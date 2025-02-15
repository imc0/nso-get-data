#!/data/data/com.termux/files/usr/bin/sh
#
# Retrieve your NSO gtoken using rooted Android device with Termux.
# Then ask Nintendo SplatNet for a bulletToken.  
# These tokens can then be pasted into s3s.
#

# Make a directory to hold cache files for this script
: ${XDG_CACHE_HOME:="$HOME"/.cache}
: ${NSODATA:="$XDG_CACHE_HOME"/nsodata}
mkdir -p "$NSODATA"
if ! [ -d "$NSODATA" ] || ! [ -w "$NSODATA" ]; then
    echo "Error: cache folder is not writeable ($NSODATA)" >&2
    exit 1
fi

# File where we will cache the current SplatNet web version:
wvfile="$NSODATA"/nso-wv-ver.txt
# Directory where we will temporarily store the cookie database:
nsodir="$NSODATA"/cookies
# Hostname of SplatNet app server:
snhost=api.lp1.av5ja.srv.nintendo.net
# Last known SplatNet web version:
wvdefault=6.0.0-9253fd84

# Check presence of essential tools
ok=true
if ! su -c "cat < /data/user/0/com.nintendo.znca/app_webview/Default/Cookies" >/dev/null; then
    cat <<EOF >&2
Error: cannot read NSO app cookie file. Either cookie cache does not exist,
or no root permission in Termux. Open SplatNet 3 in NSO app, make sure
you granted root permission to Termux in corresponding app (Magisk, KernelSU etc.)
EOF
    ok=false
fi

for cmd in sqlite3 curl perl; do
    if ! command -v "$cmd" > /dev/null; then
        echo "Error: $cmd is not in your path.  Install it from your distro." >&2
        ok=false
    fi
done
if ! $ok; then exit 1; fi

# Obtain and check the cookie file
mkdir -p "$nsodir"
chmod 700 "$nsodir"
ckfile="$nsodir/Cookies"
rm -f "$ckfile"
out="$(su -c cp /data/user/0/com.nintendo.znca/app_webview/Default/Cookies $nsodir 2>&1)"
if ! [ -f "$ckfile" ]; then
    echo "Error: did not copy the cookie file" >&2
    echo "$out" >&2
    exit 1
fi
cdate="$(stat -c %Y "$ckfile")"
ndate="$(date +%s)"
if [ "$((cdate+6*3600))" -lt $ndate ]; then
    echo "Warning: the cookie file is out of date.  Gtoken may be stale." >&2
fi

# Give Cookies file permission to everyone

su -c chmod a+rwx "$ckfile"

# Obtain and check the gtoken

g="$(sqlite3 "$nsodir"/Cookies "SELECT value from (SELECT * FROM cookies WHERE name='_gtoken' ORDER BY creation_utc DESC LIMIT 1);")"
if [ -z "$g" ]; then
    echo "Error: failed to pull the gtoken from the cookie file" >&2
    exit 1
elif [ "${#g}" -ne 926 ]; then
    echo "Warning: gtoken has the wrong length and is probably invalid" >&2
fi
echo "Your gtoken is on the next line(s):"
echo "$g"
echo ""

# Attempt to get the SplatNet web version
nsover=""
if [ -f "$wvfile" ]; then
    wdate="$(stat -c %Y "$wvfile")"
    if [ "$((wdate+48*3600))" -ge $ndate ]; then
        read nsover < "$wvfile"
    fi
fi
if [ -z "$nsover" ]; then
    # try to figure out the main JS filename from SplatNet index
    js="$(curl -s "https://$snhost/" | grep -a -o 'main\.[0-9a-f]*\.js')"
    if [ -n "$js" ]; then
        # try to parse the JS file to extract the web view version
        nsover="$(curl -s "https://$snhost/static/js/$js" | perl -lne 'print "$2$1" if /null===\(..="([0-9a-f]{8}).{60,120}`,..=`([0-9.]+-)/;')"
    fi
    if [ -n "$nsover" ]; then echo "$nsover" > "$wvfile"
    else echo "Warning: failed to get SplatNet web version from NSO. This may
mean NSO is temporarily down, or the interface has changed in a way that
prevents this script from working." >&2
    fi
fi
[ -z "$nsover" ] && nsover=$wvdefault

# Attempt to get a bulletToken from our gtoken
out="$(curl -s -X POST -H 'Content-Type: application/json' -H "X-Web-View-Ver: $nsover" -H 'accept-language: en-US' -H 'x-nacountry: US' -b "_gtoken=$g" "https://$snhost/api/bullet_tokens")"
case "$out" in
    *bulletToken*)
        bt="$(echo "$out" | tr -d \" | tr '{},' '\012' | grep bulletToken | cut -d: -f2)"
        if [ -z "$bt" ]; then echo "Error: failed to parse the bulletToken from web response" >&2
        elif [ "${#bt}" -ne 124 ]; then
            echo "Error: returned bulletToken is the wrong length" >&2
        else
            echo "Your bulletToken is on the next line(s):"
            echo "$bt"
        fi
        ;;
    *) echo "Error: Nintendo did not give us a bulletToken.
This probably means that your gtoken is stale or invalid. Try re-opening
SplatNet on the Android device, browse some data, then exit back to the
NSO menu.  Wait a few seconds, then re-run this script." >&2
       if [ -n "$out" ]; then
           echo ""
           echo "Error data: $out"
       fi
esac
