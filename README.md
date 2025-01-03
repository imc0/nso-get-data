nso-get-tokens
==============

This is a script that inspects your NSO app data on an Android device
(usually an emulated device in Android Studio) and prints out the
gtoken and bulletToken which you need in order to run s3s or any other
third-party SplatNet3 client.  

Note: NSO stands for Nintendo Switch Online and is an official Nintendo
app which allows you to browse certain aspects of your gameplay on the
*Splatoon* series of games.

Note also: this script is specific to *Splatoon 3*.

## Environment

This script has been tested on Fedora, where `/bin/sh` is bash.  It
probably works on other GNU/Linux distributions, and may also work in
other Unix-like environments with other POSIX-compatible shells, but no
guarantees.

## Requirements

 - **adb** (the Android debug bridge client).  If you have Android
   [Studio](https://developer.android.com/studio) or
   [SDK](https://developer.android.com/tools)
   then you can get this from the platform-tools package.  In Ubuntu you
   can also get it by installing the `adb` package, or in Fedora 
   the `android-tools` package.

 - Other command-line tools: **sqlite3**, **curl** and **perl**, all of which
   you may already have installed, but if not then they should be available
   from your distro.

 - An Internet connection.

 - An Android device with root debugging enabled (which is not the same as a
   rooted phone).  This most likely will not work on a real phone unless you
   root it and also
   [edit the system build.prop file](https://xdaforums.com/t/enable-adb-root-from-shell.4298567/).
   With an emulated Android device this works out of the box provided it's based
   on a system image **without Google Play**.

## Setup

 - Use the Android emulator from Android SDK.  The full Android Studio is not
   required, but it's easier to manage your devices using the Studio GUI.
   Create an emulated device (e.g. a Pixel) and be sure to pick a system image
   **without Google Play**.  Android API version 34 (i.e., Android 14) seems
   to work.

 - You will need to use `adb` to install the NSO app into the emulated device.
   This can be obtained from APKMirror.  If you end up with an `apkm` file,
   you can simply unzip that to reveal the separate APK packages.  With the
   emulated device running, use a command such as:
   ```bash
   adb install-multiple base.apk split_config.{x86_64,en,xhdpi}.apk
   ```
   (assuming your emulated device is an x86_64 device).

 - In the emulated device, start the NSO app and go through whatever steps it
   asks in order to sign in to your Nintendo Switch account.

## Obtaining your tokens
 - Start the Android device (if not already started), start up the NSO
   app, enter Splatoon 3 and browse some data.  Exit Splatoon 3 back to
   the NSO menu, and wait a few seconds.  This should ensure that the NSO
   app writes the cookie data back to storage.

 - With the emulator still running, run this script in a terminal.  If all
   goes well, it prints out your gtoken and bulletToken.
