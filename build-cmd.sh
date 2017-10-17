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

# unable to locate version info in header file or a method to
# access it so, for now, hard coding it based on observation of
# this page: https://www.bugsplat.com/docs/resources/updates
echo "3.5.0.5" > "$stage/version.txt"

build=${AUTOBUILD_BUILD_ID:=0}

case "$AUTOBUILD_PLATFORM" in
    windows)
        load_vsvars

        # prepare the staging dirs
        mkdir -p "$stage/LICENSES"
        mkdir -p "$stage/include/bugsplat"
        mkdir -p "$stage/lib/release"
        mkdir -p "$stage/bin/release"

        # copy files
        cp "$BUGSPLAT_DIR/BUGSPLAT_LICENSE.txt" "$stage/LICENSES"
        cp "$BUGSPLAT_DIR/inc/BugSplat.h" "$stage/include/bugsplat"
        cp "$BUGSPLAT_DIR/lib/BugSplat.lib" "$stage/lib/release"
        cp "$BUGSPLAT_DIR/bin/BsSndRpt.exe" "$stage/bin/release"
        cp "$BUGSPLAT_DIR/bin/BugSplat.dll" "$stage/bin/release"
        cp "$BUGSPLAT_DIR/bin/BugSplatRC.dll" "$stage/bin/release"
    ;;
    windows64)
        load_vsvars

        # prepare the staging dirs
        mkdir -p "$stage/LICENSES"
        mkdir -p "$stage/include/bugsplat"
        mkdir -p "$stage/lib/release"
        mkdir -p "$stage/bin/release"

        # copy files
        cp "$BUGSPLAT_DIR/BUGSPLAT_LICENSE.txt" "$stage/LICENSES"
        cp "$BUGSPLAT_DIR/inc/BugSplat.h" "$stage/include/bugsplat"
        cp "$BUGSPLAT_DIR/lib64/BugSplat64.lib" "$stage/lib/release"
        cp "$BUGSPLAT_DIR/bin64/BsSndRpt64.exe" "$stage/bin/release"
        cp "$BUGSPLAT_DIR/bin64/BugSplat64.dll" "$stage/bin/release"
        cp "$BUGSPLAT_DIR/bin64/BugSplatRc64.dll" "$stage/bin/release"
    ;;
    darwin*)
        echo "This project is not currently supported for $AUTOBUILD_PLATFORM" 1>&2 ; exit 1
    ;;
    linux*)
        echo "This project is not currently supported for $AUTOBUILD_PLATFORM" 1>&2 ; exit 1
    ;;
esac
