# This script is sourced by the viewer's build.sh. It relies on variables and
# shell functions provided by build.sh in the viewer build environment.

# Don't even bother uploading symbols for anything but the Release build.
if [ "$variant" == "Release" ]
then
     # Our build-cmd.sh copies SendPdbs.exe to bin/release, and our
     # autobuild.xml ensures that it's packaged in the tarball.
     # Because we invoke SendPdbs via SendPdbs.bat, use native_path.
     export SendPdbs="$(native_path "${build_dir}/packages/bin/release/SendPdbs.exe")"

     # viewer version -- explicitly ditch '\r' as bash only strips '\n'
     export version="$(tr <"${build_dir}/newview/viewer_version.txt" -d '\r')"

     # SendPdbs wants a single /f argument in which individual pathnames are
     # separated by ';'
     function strjoin {
         local IFS="$1"
         shift
         echo "$*"
     }

     # for some reason bugsplat requires uploading exe that match the ones we ship to users
     # Win 10 specific. Upload files using final exe name (viewer will be adjusted separately
     # to use same name)
     reldir="${build_dir}/newview/Release"
     filelist=("$(native_path "$reldir/secondlife-bin.pdb")")
     exe_file="$reldir/SecondLifeViewer.exe"
     if [ -e "$exe_file" ]
     then
         filelist+=("$(native_path "$exe_file")")
     else
         # Compatibility for older builds
         filelist+=("$(native_path "$reldir/secondlife-bin.exe")")
     fi

     # don't echo credentials
     set +x
     # SL-19854: specifying /u and /p arguments, we kept hitting
     # ERROR: The /u (user) or /credentials argument must be specified or set
     # by environment variable 'BugSplatUser'
     # ERROR: The /p (password) or /credentials argument must be specified or
     # set by environment variable 'BugSplatPassword'
     # Shrug, setting those environment variables seems to work better.
     export BugSplatUser="$BUGSPLAT_USER"
     export BugSplatPassword="$BUGSPLAT_PASS"
     set -x

     export files="$(strjoin ';' "${filelist[@]}")"

     # All parameters are passed via environment variables, which is why
     # various variables set above are exported.
     mydir="$(dirname "$BASH_SOURCE")"
     "$mydir/SendPdbs.bat" || fatal "BugSplat SendPdbs failed"
fi
