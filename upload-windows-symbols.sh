# This script is sourced by the viewer's build.sh. It relies on variables and
# shell functions provided by build.sh in the viewer build environment.

# Don't even bother uploading symbols for anything but the Release build.
if [ "$variant" == "Release" ]
then
     # Our build-cmd.sh copies SendPdbs.exe to bin/release, and our
     # autobuild.xml ensures that it's packaged in the tarball
     SendPdbs="${build_dir}/packages/bin/release/SendPdbs.exe"

     # viewer version -- explicitly ditch '\r' as bash only strips '\n'
     version="$(tr <"${build_dir}/newview/viewer_version.txt" -d '\r')"

     # SendPdbs wants a single /f argument in which individual pathnames are
     # separated by ';'
     function wildjoin {
         local IFS="$1"
         shift
         echo "$*"
     }

     # upload to BugSplat -- don't echo credentials
     set +x

     # need BugSplat credentials to post symbol files
     # defines BUGSPLAT_USER and BUGSPLAT_PASS
     source "$build_secrets_checkout/bugsplat/bugsplat.sh"

     # for some reason bugsplat requires uploading exe that match the ones we ship to users
     # Win 10 specific. Upload files using final exe name (viewer will be adjused separately
     # to use same name)
     exe_file="${build_dir}/newview/Release/SecondLifeViewer.exe"
     if [ -e "$exe_file" ]
     then
         files="$(wildjoin ';' "${build_dir}/newview/Release"/{secondlife-bin.pdb,SecondLifeViewer.exe})"
     else
         # Compatibility for older builds
         files="$(wildjoin ';' "${build_dir}/newview/Release"/secondlife-bin.{pdb,exe})"
     fi

     args=(/a "$viewer_channel" \
           /v "$version" \
           /b "$BUGSPLAT_DB" \
           /f "$files")
     echo "$SendPdbs" /u xxx /p xxx "${args[@]}"
     "$SendPdbs" /u "$BUGSPLAT_USER" /p "$BUGSPLAT_PASS" "${args[@]}"
     rc=$?

     set -x

     [ $rc -eq 0 ] || fatal "BugSplat SendPdbs failed"
fi
