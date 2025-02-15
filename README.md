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

[Emulator Guide](#emulator-guide)

[Termux with Root Guide](#termux-with-root-guide)

# Emulator Guide

Use [nso-get-tokens.sh](./nso-get-tokens.sh)

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

# Termux with Root Guide

Use [nso-get-tokens-termux.sh](./nso-get-tokens-termux.sh)

## Environment

This script has been tested on a real Android phone, with KernelSU and Termux installed. 
It may work on Magisk or other `su` programs, however no guarantees either.

## Requirements

 - **Termux** (a terminal emulator with `apt`). 
   You should get **Termux** from [GitHub Releases](https://github.com/termux/termux-app/releases/latest) or [F-Droid](https://f-droid.org/en/packages/com.termux/). 
   **DO NOT install from Google Play** as [it should be considered an unofficial/forked release source](https://github.com/termux/termux-app/discussions/4000).

 - Other command-line tools: **sqlite3**, **curl** and **perl**, all of which
   you may already have installed, but if not then they should be available
   from your Termux apt.
   
 - An Internet connection.

 - An Android device with Root access. 
   This script was tested on [KernelSU](https://kernelsu.org/) rooted phone.
   [Magisk](https://github.com/topjohnwu/Magisk) may work too.

 - Just in case:
   In order to use NSO app on an Android with Root access, 
   you need to properly hide your Root for NSO app. Or it instantly exits.

## Setup

 - Install **Termux** on your device.

 - Grant Root access to **Termux** with your Root Manager (usually in Magisk, KernelSU app).

 - Hide your Root to NSO app, otherwise it will refuse to run at all.

 - Copy the script to **Termux** home directory. It's usually `/data/data/com.termux/files/home`, 
   or you could copy via Android built-in File Browser.

 - Install `sqlite` `curl` `perl` packages: `pkg install -y sqlite curl perl`

 - Start NSO app and sign in to your Nintendo Account.

## Obtaining your tokens
 - Start the Android device (if not already started), start up the NSO
   app, enter Splatoon 3 and browse some data.  Exit Splatoon 3 back to
   the NSO menu, and wait a few seconds.  This should ensure that the NSO
   app writes the cookie data back to storage.

 - Run this script in **Termux**.  If all goes well, 
   it prints out your gtoken and bulletToken.
