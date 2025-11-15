#!/usr/bin/env bash

cd "$(dirname "$0")"

# turn on verbose debugging output for parabuild logs.
exec 4>&1; export BASH_XTRACEFD=4; set -x

# make errors fatal
set -e

# complain about unset env variables
set -u

if [ -z "$AUTOBUILD" ] ; then
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

top="$(pwd)"
stage="$(pwd)/stage"

BUGSPLAT_DIR="$top/BugSplat"

# load autobuild provided shell functions and variables
source_environment_tempfile="$stage/source_environment.sh"
"$autobuild" source_environment > "$source_environment_tempfile"
. "$source_environment_tempfile"

build=${AUTOBUILD_BUILD_ID:=0}

# prepare the staging dirs
mkdir -p "$stage/LICENSES"
mkdir -p "$stage/include/bugsplat"
mkdir -p "$stage/lib/release"
mkdir -p "$stage/bin/release"
mkdir -p "$stage/upload-extensions"

case "$AUTOBUILD_PLATFORM" in
    windows*)
        load_vsvars

        if [ "$AUTOBUILD_PLATFORM" == "windows64" ]
        then
            sfx="64"
            bin="Bugsplat/x64/Release"
            rcdll="BugSplatRc64.dll"
        else
            sfx=""
            bin="Bugsplat/Win32/Release"
            rcdll="BugSplatRC.dll"
        fi

        # cygwin bash incantation to eliminate FRIGGING CARRIAGE RETURN
        set -o igncr
        # BugSplat version info seems to be platform-dependent and even
        # component-dependent?! Query the Windows version by asking for the
        # version stamped into this BugSplat .exe. Magic courtesy of Raymond
        # Chen:
        # https://devblogs.microsoft.com/oldnewthing/20180529-00/?p=98855
        BUGSPLAT_VERSION="$(powershell -Command \
          "(Get-Command $(cygpath -w $BUGSPLAT_DIR/BugSplat/Win32/Release/BsSndRpt.exe)).FileVersionInfo.FileVersion")"
        # PowerShell returns a version like "4, 0, 3, 0" -- use dots instead
        BUGSPLAT_VERSION="${BUGSPLAT_VERSION//, /.}"

        # copy files
        cp "$BUGSPLAT_DIR/BugSplat/inc/BugSplat.h" "$stage/include/bugsplat"
        # force to simple name since we can't branch on 32/64 in CMake files
        cp "$BUGSPLAT_DIR/$bin/BugSplat$sfx.lib" "$stage/lib/release/BugSplat.lib"
        cp "$BUGSPLAT_DIR/$bin/BsSndRpt$sfx.exe" "$stage/lib/release"
        cp "$BUGSPLAT_DIR/$bin/BugSplat$sfx.dll" "$stage/lib/release"
        cp "$BUGSPLAT_DIR/$bin/$rcdll" "$stage/lib/release"

        # There's only one symbol-upload-windows.exe, and it's in tools.
        cp -v "$BUGSPLAT_DIR/Tools"/symbol-upload-windows.exe* "$stage/bin/release/"
        cp -v "$top/upload-windows-symbols.sh" "$stage/upload-extensions/"
        cp -v "$top/SendPdbs.bat" "$stage/upload-extensions/"
    ;;
    darwin*)
	# Establish locations of prebuilt frameworks
        bgst_framework="$top/BugSpaltxcframework/BugSplat.xcframework/macos-arm64_x86_64/BugsplatMac.framework"
        crprt_framework="$top/BugSpaltxcframework/CrashReporter.xcframework/macos-arm64_x86_64/CrashReporter.framework"
        hockey_framework="$top/BugSpaltxcframework/HockeySDK.xcframework/macos-arm64_x86_64/HockeySDK.framework"

        # BugsplatMac version embedded in the framework's Info.plist
        BUGSPLAT_VERSION="1.2.6"

        # Because of its embedded directory symlinks, copying the framework
        # works much better if we kill the previous copy first.
        stage_framework="$stage/lib/release/$(basename "$bgst_framework")"
        [ -d "$stage_framework" ] && rm -rf "$stage_framework"
        stage_framework="$stage/lib/release/$(basename "$crprt_framework")"
        [ -d "$stage_framework" ] && rm -rf "$stage_framework"
        stage_framework="$stage/lib/release/$(basename "$hockey_framework")"
        [ -d "$stage_framework" ] && rm -rf "$stage_framework"

        # Extract the content.
        cp -R "$bgst_framework" "$stage/lib/release"
        cp -R "$crprt_framework" "$stage/lib/release"
        cp -R "$hockey_framework" "$stage/lib/release"

        # Now set up the upload-extensions script that will engage it.
        cp -v "$top/upload-archive.sh" "$stage/upload-extensions/"
        cp -v "$top/upload-mac-symbols.sh" "$stage/upload-extensions/"
    ;;
    linux*)
        echo "This project is not currently supported for $AUTOBUILD_PLATFORM" 1>&2 ; exit 1
    ;;
esac
echo "$BUGSPLAT_VERSION-$build" > "$stage/version.txt"
cp "$BUGSPLAT_DIR/BUGSPLAT_LICENSE.txt" "$stage/LICENSES"
