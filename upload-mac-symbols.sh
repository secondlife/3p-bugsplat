# This script is sourced by the viewer's build.sh. It relies on variables and
# shell functions provided by build.sh in the viewer build environment.

# Don't even bother uploading symbols for anything but the Release build.
if [ "$variant" == "Release" ]
then
     # BugSplat's upload-archive.sh script (as patched in our 3p repo) is
     # found in the BugsplatMac framework we installed.
     # We call their upload-archive.sh script, instead of performing the key
     # actions inline, because it contains magic (potentially subject to
     # upstream change) such as the specific URL path to which to post the
     # symbol archives, and the curl login/cookie dance needed to authenticate
     # to their server. This way, subsequent upstream changes will be merged
     # with our patches, and life goes on.
     upload_archive="${build_dir}/packages/lib/release/BugsplatMac.framework/Versions/Current/Resources/upload-archive.sh"

     # Our patched upload_archive script requires the path to the (embedded)
     # .app as its first argument, and the path to the zipped archive as the
     # second.
     app_dir="${build_dir}/newview/${variant}"
     app="$(ls -d "${app_dir}"/*.app/"Contents/Resources/Second Life Viewer.app")"
     xcarchive="$(ls -d "${app_dir}"/*.xcarchive.zip)"

     # upload to BugSplat -- don't echo credentials
     set +x

     # need BugSplat credentials to post symbol files
     # defines BUGSPLAT_USER and BUGSPLAT_PASS
     source "$build_secrets_checkout/bugsplat/bugsplat.sh"
     export BUGSPLAT_USER
     export BUGSPLAT_PASS

     "$upload_archive" "$app" "$xcarchive"
     rc=$?

     set -x

     [ $rc -eq 0 ] || fatal "BugSplat upload_archive.sh failed"
fi
