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
            lib="lib64"
            bin="bin64"
            sfx="64"
            rcdll="BugSplatRc64.dll"
        else
            lib="lib"
            bin="bin"
            sfx=""
            rcdll="BugSplatRC.dll"
        fi

        # BugSplat version info seems to be platform-dependent and even
        # component-dependent?! Query the Windows version by asking for the
        # version stamped into this BugSplat .exe.
        BUGSPLAT_VERSION="$("$top/query_version.sh" "$BUGSPLAT_DIR/bin/BsSndRpt.exe")"

        # copy files
        cp "$BUGSPLAT_DIR/inc/BugSplat.h" "$stage/include/bugsplat"
        # force to simple name since we can't branch on 32/64 in CMake files
        cp "$BUGSPLAT_DIR/$lib/BugSplat$sfx.lib" "$stage/lib/release/BugSplat.lib"
        cp "$BUGSPLAT_DIR/$bin/BsSndRpt$sfx.exe" "$stage/lib/release"
        cp "$BUGSPLAT_DIR/$bin/BugSplat$sfx.dll" "$stage/lib/release"
        cp "$BUGSPLAT_DIR/$bin/$rcdll" "$stage/lib/release"

        # There's only one SendPdbs.exe, and it's in bin, not in bin64.
        # Include SendPdbs.exe.config.
        cp -v "$BUGSPLAT_DIR/bin"/SendPdbs.exe* "$stage/bin/release/"
        cp -v "$BUGSPLAT_DIR/bin/PdbLibrary.dll" "$stage/bin/release/"
        cp -v "$top/upload-windows-symbols.sh" "$stage/upload-extensions/"
    ;;
    darwin*)
        # BugsplatMac version embedded in the framework's Info.plist
        framework="$top/Carthage/Build/Mac/BugsplatMac.framework"
        Info_plist="$framework/Resources/Info.plist"
        BUGSPLAT_VERSION="$(python -c "import plistlib
print plistlib.readPlist('$Info_plist')['CFBundleShortVersionString']")"
        # Because of its embedded directory symlinks, copying the framework
        # works much better if we kill the previous copy first.
        stage_framework="$stage/lib/release/$(basename "$framework")"
        [ -d "$stage_framework" ] && rm -rf "$stage_framework"
        # We don't (yet) build from BugsplatMac source -- we just check in,
        # and copy, the prebuilt version downloaded from BugSplat (sigh).
        cp -R "$framework" "$stage/lib/release"
        # However, we do have a patched version of their upload-archive.sh
        # script in the BugsplatMac source tree. Make sure that gets into the
        # newly-copied framework.
        cp -v "$top/BugsplatMac/upload-archive.sh" \
              "$stage_framework/Versions/Current/Resources/"
        # Now set up the upload-extensions script that will engage it.
        cp -v "$top/upload-mac-symbols.sh" "$stage/upload-extensions/"
    ;;
    linux*)
        echo "This project is not currently supported for $AUTOBUILD_PLATFORM" 1>&2 ; exit 1
    ;;
esac
echo "$BUGSPLAT_VERSION.$build" > "$stage/version.txt"
cp "$BUGSPLAT_DIR/BUGSPLAT_LICENSE.txt" "$stage/LICENSES"
