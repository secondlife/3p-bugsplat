# Invoke wmic to query the version of a particular .exe or .dll.
# The actual wmic command is in our companion .bat file since it seems to
# matter to wmic whether it's invoked from cygwin bash or cmd.exe.
# Moreover:
# - you must pass the FULL pathname of the file (hence realpath)
# - every backslash must be doubled (??? -- hence sed)
prog="$(cygpath -w "$(realpath "$1")" | sed 's/\\/\\\\/g')"
# Invoke the .bat file by the same name as this script.
# Naturally it couldn't be as easy as wmic just spitting out the version
# number: there are a whole bunch of blank lines before and after (hence grep)
# and the actual output is 'Version=blah' (hence cut).
"${0%.sh}.bat" "$prog" | grep 'Version=' | cut -d= -f2
