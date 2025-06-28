#!/bin/sh
#
# Retrieve your NSO gtoken by connecting to a virtual Android device
# and querying NSO's cookie database.  Then ask Nintendo SplatNet
# for a bulletToken.  These tokens can then be pasted into s3s.
#

# If adb is not on your path, write the full path here:
adb=adb
# Optional extra args to supply to adb (e.g. '-e')
adbargs=""

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
wvdefault=10.0.0-88706e32
# Location of the Cookies file on the device
cookiesfile=/data/user/0/com.nintendo.znca/app_webview/Default/Cookies
# Default name of the s3s config
def_s3sconf="config.txt"

# Argument processing and help
help () {
    cat <<EOH >&2
Usage: $0 [flags] [s3s_config]
where valid flags are:
    -C | -cache  don't pull cookies from the device; use the cached file
    -h | -help   print this help
    -ssh DEST[:PORT] use ssh to contact the device
    -su          Android device needs 'su' to access the NSO database
    -w | -write  write tokens to config.txt (or named s3s config)
and s3s_config is the config file for s3s (implies -w if present)
EOH
}

use_adb=true
use_su=false
use_cache=false
ssh=""
port=""
s3sconf=""
do_write=false
while [ $# -gt 0 ]; do
    flag="$1"
    # strip double '-' so that --flag is the same as -flag
    if [ "$flag" != "${flag#--}" ]; then
        flag="${flag#-}"
    fi
    case "$flag" in
    -h|-help)
        help; exit ;;
    -su)
        use_su=true ;;
    -C|-cache)
        use_cache=true
        use_adb=false ;;
    -ssh)
        if [ $# = 1 ]; then
            echo "Error: -ssh needs an argument" >&2
            exit 1
        fi
        shift
        use_adb=false
        ssh="$1"
        port="${ssh##*:}"
        case "$port" in
            "$ssh")   port="" ;;
            *[!0-9]*) port="" ;;
            *)        ssh="${ssh%:*}"
        esac
        ;;
    -w|-write)
        do_write=true ;;
    -*)
        echo "Unrecognised argument: '$flag' (use -h for help)" >&2
        exit 1
        ;;
    *)
        if [ -n "$s3sconf" ]; then
            echo "Error: extra argument: '$flag' (use -h for help)" >&2
            exit 1
        fi
        s3sconf="$1"
        do_write=true
    esac
    shift
done

# Check s3s config (if supplied)
if $do_write; then
    [ -z "$s3sconf" ] && s3sconf="$def_s3sconf"
    if ! [ -e "$s3sconf" ]; then
        echo "Error: $s3sconf: file does not exist" >&2
        exit 1
    elif ! [ -f "$s3sconf" ]; then
        echo "Error: $s3sconf: not a regular file" >&2
        exit 1
    elif ! [ -r "$s3sconf" ]; then
        echo "Error: $s3sconf: file is not readable" >&2
        exit 1
    elif ! [ -w "$s3sconf" ]; then
        echo "Error: $s3sconf: file is not writable" >&2
        exit 1
    fi
    read test < "$s3sconf"
    if [ "$test" != "{" ] || ! grep -q gtoken "$s3sconf"; then
        echo "Error: $s3sconf: does not look like an s3s config file" >&2
        exit 1
    fi
fi

# Check presence of essential tools
ok=true
if $use_adb; then
    if ! command -v "$adb" >/dev/null; then
        cat <<EOF >&2
Error: adb is not on your path. You can get it from Android SDK in the
platform-tools package, or maybe from your distro in the android-tools
or adb package. If it is installed, you can edit this script to specify
the full path.
Current value: adb=$adb
EOF
        ok=false
    fi
fi
cmds="sqlite3 curl perl"
if [ -n "$ssh" ]; then
    if $su; then cmds="$cmds ssh"
    else cmds="$cmds scp"
    fi
fi
for cmd in $cmds; do
    if ! command -v "$cmd" > /dev/null; then
        echo "Error: $cmd is not in your path.  Install it from your distro." >&2
        ok=false
    fi
done
if ! $ok; then exit 1; fi

if $use_adb && ! $use_su; then
    # Check adb root
    out="$("$adb" $adbargs root 2>&1)"
    case "$out" in
        *"more than"*)
            echo "Error: $out" >&2
            echo "You can edit this script to add adb arguments in order to specify
which device to connect to." >&2
            exit 1
            ;;
        *"no devices"*|*"unable to connect"*)
            echo "Error: $out" >&2
            echo "Please make sure your Android device is running." >&2
            exit 1
            ;;
        *production*)
            echo "Error: you do not have adb root on your device. If you are using an
Android emulator you must select a system image without Google Play.
Alternatively, use the -su flag if your device is rooted." >&2
            exit 1
            ;;
        *restarting*|*already*)
            # everything OK
            ;;
        *cannot*)
            # unknown but this is probably an error
            echo "Error: $out" >&2
            exit 1
            ;;
        *)
            # unknown and it might not be an error
            echo "$out" >&2
    esac
fi

# Obtain and check the cookie file
ckfile="$nsodir/Cookies"
if $use_cache; then
    if ! [ -r "$ckfile" ]; then
        echo "Error: there is no cached Cookies file for -cache to use" >&2
        exit 1
    fi
else
    mkdir -p "$nsodir"
    chmod 700 "$nsodir"
    rm -f "$ckfile"
    if [ -n "$ssh" ]; then
        if $use_su; then
            out="$(ssh -x ${port:+-p} $port "$ssh" "su -c 'cat \"$cookiesfile\"'" 2>&1 > "$ckfile")"
        else
            out="$(scp ${port:+-P} $port -p "$ssh":"$cookiesfile" "$ckfile" 2>&1)"
        fi
        if ! [ -s "$ckfile" ] ; then
            echo "Error: did not copy the cookie file from ssh.  Check your access" >&2
            $use_su || echo "and add the -su flag if you need to switch to root on the device." >&2
            echo "$out" >&2
            exit 1
        fi
    else # use adb
        if $use_su; then
            out="$("$adb" $adbargs shell su -c "cat $cookiesfile" 2>&1 > "$ckfile")"
        else
            out="$("$adb" $adbargs pull -a "$cookiesfile" "$ckfile" 2>&1)"
        fi
        if ! [ -f "$ckfile" ]; then
            echo "Error: adb did not pull the cookie file" >&2
            echo "$out" >&2
            exit 1
        fi
    fi
fi
cdate="$(stat -c %Y "$ckfile")"
ndate="$(date +%s)"
if [ "$((cdate+6*3600))" -lt $ndate ]; then
    echo "Warning: the cookie file is out of date.  Gtoken may be stale." >&2
fi

# Obtain and check the gtoken
g="$(sqlite3 "$nsodir"/Cookies "select value from cookies where name='_gtoken' order by creation_utc desc limit 1;")"
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
bt=""
case "$out" in
    *bulletToken*)
        bt="$(echo "$out" | tr -d \" | tr '{},' '\012' | grep bulletToken | cut -d: -f2)"
        if [ -z "$bt" ]; then echo "Error: failed to parse the bulletToken from web response" >&2
        elif [ "${#bt}" -ne 124 ]; then
            echo "Error: returned bulletToken is the wrong length" >&2
            bt=""
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

if $do_write && [ -n "$bt" ]; then
    out="$(perl -i.bak -lpe "my \$gt='$g';my \$bt='$bt';"'
        $_="    \"gtoken\": \"$gt\"," if /"gtoken":/;
        $_="    \"bullettoken\": \"$bt\"," if /"bullettoken":/;
    ' "$s3sconf" 2>&1)"
    if [ $? -eq 0 ]; then
        if [ -z "$out" ]; then
            echo "Config file '$s3sconf' written"
        else
            echo "$out" >&2
            echo "Warning: config file '$s3sconf' may not have been written" >&2
        fi
    else
        echo "An error occurred while writing the config file '$s3sconf'"
        if ! [ -s "$s3sconf" ] && [ -s "$s3sconf.bak" ]; then
            mv "${s3sconf}.bak" "$s3sconf"
            echo "Original file restored"
        fi
    fi
fi
