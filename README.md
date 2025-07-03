nso-get-tokens
==============

This is a script that inspects your NSA app data on an Android device
and prints out or saves the gtoken and bulletToken which you need in
order to run [s3s](https://github.com/frozenpandaman/s3s/) or any other
third-party SplatNet3 client.

Note: NSA stands for Nintendo Switch App (previously named Nintendo
Switch Online) and is an official Nintendo app which allows you to
browse certain aspects of your gameplay on the *Splatoon* series of
games.

Note also: this script is specific to *Splatoon 3*.

## Environment

This script has been tested on Fedora, where `/bin/sh` is bash.  It
probably works on other GNU/Linux distributions, and may also work in
other Unix-like environments with other POSIX-compatible shells, but no
guarantees.

Alternatively, you can run it directly on the Android device using Termux.[^1]
This may be particularly of interest if you don't have a Unix environment
on your computer.

## About your Android device

This basically requires rooting your phone or your Android emulator,
for example with [Magisk](https://github.com/topjohnwu/Magisk) or
[KernelSU](https://kernelsu.org/).

An exception is if you are running [LineageOS](https://lineageos.org/)
because you can turn on root debugging in the options without installing
any root app (this may also be available in other custom ROMs).

In theory if you are using an emulator then selecting an image without
Google Play allows root debugging on the device.  However, 
Nintendo Switch App (as of version 3.0) is not known to work in
this environment and in fact seems to require a **32-bit system image
with Google Play** when running in an emulator on an Intel processor.
You therefore have to root this system image because Google Play images
don't have root debugging.

If your Android system is rooted then you must enforce a deny list in
your root manager and add Nintendo Switch App to that list, or it will
not work.  If NSA gives you a communication error with code 2817-0583
then the chances are that it has detected that you are running in a
modified environment.

## Requirements

It goes without saying that on your Android device you need Nintendo
Switch App and an Internet connection.  In addition the script also
needs Internet access to contact Nintendo's SplatNet API as this is
how it turns your `gtoken` into a `bulletToken`.

If you are running this script on a GNU/Linux host then you need:

 - Command-line tools: **sqlite3**, **curl** and **perl**, all of which
   you may already have installed, but if not then they should be available
   from your distro.

 - At least one of the following:

   - **adb** (the Android debug bridge client) for Linux.  If you have Android
     [Studio](https://developer.android.com/studio) or
     [SDK](https://developer.android.com/tools)
     then you can get this from the platform-tools package.  In Ubuntu you
     can also get it by installing the `adb` package, or in Fedora 
     the `android-tools` package.

   - [Magisk SSH module](https://github.com/Magisk-Modules-Repo/ssh) for your
     Android device.[^2]

   - [Termux](https://wiki.termux.com/wiki/Main_Page) on your Android device
     with [remote access](https://wiki.termux.com/wiki/Remote_Access) enabled.

If you are running the script under Termux then the command-line tools
(**sqlite3**, **curl** and **perl**) need to be installed from the
Termux package system (see below for further instructions).  Remote access
is not needed in this case as you are running on the Android device directly.

## Obtaining your tokens
 - See the Setup section below for the scenario you wish to use.

 - Start the Android device (if not already started), start up the NSA
   app, enter Splatoon 3 and browse some data.  Wait a few seconds.  The
   aim is to let the WebView component within the NSA app write its cookie
   data back to storage, which can take up to 30 seconds but is often
   quicker.

 - Run this script in a terminal.  If all goes well, it prints out your
   gtoken and bulletToken.  There are more options: scroll to the bottom
   of this page for a full list.

 - If you have a `config.txt` from `s3s` in the current directory then
   you can add the `-w` flag to this script to write your tokens to this
   config.  Then you can run `s3s` to use the tokens.  If the config file
   is somewhere else, you can write the file path as an argument to this
   script to write the tokens to that file.

## Setup for using an emulator

 - Use the Android emulator from Android SDK.  The full Android Studio is not
   required, but it's easier to manage your devices using the Studio GUI.
   Create an emulated device (e.g. a Pixel) and pick a system image for
   **Android 11 (x86) with Google Play** (Android API level 30).

 - You can either sign into Google Play to install the NSA app or
   use `adb` to install it into the emulated device.  When doing the
   latter, the app can be obtained from APKMirror.  If you end up with
   an `apkm` file, you can simply unzip that to reveal the separate APK
   packages.  With the emulated device running, use a command such as:
   ```bash
   adb install-multiple base.apk split_config.{x86,en,xhdpi}.apk
   ```

 - Use [rootAVD](https://gitlab.com/newbit/rootAVD) or
   [Magisk](https://github.com/topjohnwu/Magisk) directly (or any other
   method) to install Magisk on your emulated device.  Then with the device
   running, open Magisk, go to settings and enforce the deny list.  Add
   Nintendo Switch App to the deny list.

 - In the emulated device, start the NSA app and go through whatever steps it
   asks in order to sign in to your Nintendo Switch account.

 - When you run this script to get your tokens, add the `-su` flag.

## Setup for using a LineageOS phone

 - Enable [Developer Options](https://www.android.com/intl/en_uk/articles/enable-android-developer-settings/)
   in Settings.

 - Go to System, Advanced, Developer Options and enable both USB Debugging and
   Root Debugging.

 - Install and use Nintendo Switch App as usual.

 - Connect the phone to your computer with a USB cable (or enable Wi-Fi
   debugging – you might need to issue an `adb connect` command in order
   for that to work).

 - This script doesn't need any special flags when you run it.

## Setup for using a rooted Android phone 

 - Install and use Nintendo Switch App as usual.

 - Make sure Nintendo Switch App is in the deny list in your root manager app.

 - If you are using a USB cable (or Wi-Fi debugging):

   - When you run this script to get your tokens, add the `-su` flag.

 - If you have [Magisk SSH module](https://github.com/Magisk-Modules-Repo/ssh):

   - Find out the IP address of your phone (you may find it in Network Details
     in the Wi-Fi settings for the network you are connected to).

   - When you run this script add: `-ssh root@`*IP_ADDRESS*.

 - If you have [remote access](https://wiki.termux.com/wiki/Remote_Access)
   with Termux but are running the script on your computer:

   - Find out the IP address of your phone (it will be in the output of the
     command `ifconfig` in Termux).

   - When you run this script add: `-ssh `*IP_ADDRESS*`:8022 -su` .

## Setup for using Termux on a rooted Android phone

Termux is a terminal emulator for Android giving you a Unix-like shell with
a package manager.  You can run this script in that shell, and even run `s3s`
as well.

The recommended sources for installing Termux are
[F-Droid](https://f-droid.org/en/packages/com.termux/) and
[GitHub](https://github.com/termux/termux-app/releases/latest).
The version on [Google Play](https://play.google.com/store/apps/details?id=com.termux)
is a redacted version made to meet Google's requirements for Play Store apps
and its initial release was considered controversial by some, but
nevertheless it will work for our purposes.  The differences are explained
on the GitHub page for [termux-play-store](https://github.com/termux-play-store)
and there is also a [Reddit post](https://www.reddit.com/r/termux/comments/1dbujal/)
about it.

 - Grant root access to Termux with your root manager.  You can request
   and/or check access by typing in Termux "`su -c id`" and it should respond
   "`uid=0(root)`" (etc).

 - If you are using Magisk: open the Magisk settings.  Under the Superuser
   heading find the setting Mount Namespace Mode and set it to
   Global Namespace.

 - In Termux install the dependencies with:
   ```
   pkg install sqlite curl perl
   ```

 - Copy the script into Termux.  The location is usually
   `/data/data/com.termux/files/home` which you may be able to access
   from `adb` or with an Android file manager such as
   [Material Files](https://play.google.com/store/apps/details?id=me.zhanghai.android.files).
   Or in Termux you can install `git` (`pkg install git`) and then clone a copy
   of this repo.

 - Install and use Nintendo Switch App as usual.

 - Make sure Nintendo Switch App is in the deny list in your root manager app.

 - Run this script in Termux and it should print out your tokens.  You shouldn't
   need any specific flags because the script detects Termux and automatically
   adds the flags `-termux -su` where necessary.

 - If you also want to run `s3s`:

   - Install `git` and `python` into Termux if they are not already installed:
     ```
     pkg install git python
     ```

   - Clone the [s3s](https://github.com/frozenpandaman/s3s/) repo with git:
     ```
     git clone https://github.com/frozenpandaman/s3s.git
     ```

   - Change to the s3s directory: `cd s3s`

   - Run s3s once to generate your config file:
     ```
     python s3s.py -r
     ```
     You'll need your stat.ink API key (available in [settings](https://stat.ink/profile)).
     Type `skip` when it asks you to log in to your Nintendo account.
     Type Ctrl-C to interrupt it when it asks for your gtoken.

   - Copy the `nso-get-tokens.sh` script into this directory (or just run it
     from where it is).  Run it with the `-w` flag to write your tokens to `config.txt`.

   - Run s3s again with your chosen flags to upload battle data.

## Command reference for this script

### Synopsis

```
nso-get-tokens.sh [flags] [s3s_config]
```

### Flags

 - `-c` or `-cache`  
   If you recently obtained tokens from your device, you can re-print the
   tokens from the cached cookie file instead of accessing the device again.
   Note that the script will still contact SplatNet to validate the gtoken
   and obtain a bulletToken.

 - `-h` or `-help`  
   Print a short help message explaining these options and exit.

 - `-ssh [`*USER*`@]`*ADDR*`[:`*PORT*`]`  
   Access the Android device using SSH protocol.  The *USER@ADDR* syntax is
   used exactly as in normal SSH; as an extension to the syntax you may also
   add a colon and a port number to the SSH destination.

 - `-su`  
   Signifies that the script needs to elevate privileges after connecting to
   the device.  You generally need this unless (a) you have root debugging
   or (b) you are connecting as the root user via SSH.

 - `-termux`  
   Tells the script to operate in Termux mode (i.e., running locally on the
   Android device).  It's not usually necessary to specify this flag because
   the script should detect whether it's running in Termux.

 - `-w` or `-write`  
   Write tokens to a config file after obtaining them.  The config file must
   exist and be in the format that `s3s` uses, or this script will reject it.
   The config file will be named `config.txt` and be in the current directory,
   or you can explicitly name the file (in which case saying `-w` is optional).

### Arguments

 - *s3s_config*  
   Optionally names a file that the tokens will be written to.  See the
   `-w` flag above for details, but note that specifying a file name
   implies `-w` so the flag itself is optional in that case.

[^1]: Thanks to @hedw1gP for the idea of using Termux.
[^2]: Thanks to @Thulinma for the idea of using Magisk SSH.
