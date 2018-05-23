# This script is sourced by the viewer's build.sh. It relies on variables and
# shell functions provided by build.sh in the viewer build environment.

# Don't even bother uploading symbols for anything but the Release build.
if [ "$variant" == "Release" ]
then
     # Our build-cmd.sh copies SendPdbs.exe to bin/release, and our
     # autobuild.xml ensures that it's packaged in the tarball
     SendPdbs="${build_dir}/packages/bin/release/SendPdbs.exe"

     # viewer channel
     build_data="$(cygpath -m "${build_dir}/build_data.json")"
     channel="$(python -c "import sys, json
sys.stdout.write(json.load(open(r'$build_data'))['Channel'])")"

     # viewer version -- explicitly ditch '\r' as bash only strips '\n'
     version="$(tr <"${build_dir}/newview/viewer_version.txt" -d '\r')"

     pushd "${build_dir}/newview/Release"

     # upload to BugSplat -- don't echo credentials
     set +x

     # need BugSplat credentials to post symbol files
     # defines BUGSPLAT_USER and BUGSPLAT_PASS
     source "$build_secrets_checkout/bugsplat/bugsplat.sh"

     args=(/a "$channel" /v "$version" /b second_life_callum_test \
           /f "secondlife-bin.pdb;secondlife-bin.exe")
     echo "$SendPdbs" /u xxx /p xxx "${args[@]}"
     "$SendPdbs" /u "$BUGSPLAT_USER" /p "$BUGSPLAT_PASS" "${args[@]}"

     set -x
     popd
fi
