#!/bin/bash
#
# (Above line comes out when placing in Xcode scheme)
#

LOG="/dev/stdout"

if [ -z "$BUGSPLAT_USER" -o -z "$BUGSPLAT_PASS" ]
then ## skip all this if credentials are already set in environment
if [ ! -f "${HOME}/.bugsplat.conf" ]
then
    echo "Missing bugsplat config file: ~/.bugsplat.conf" >> $LOG 2>&1
    exit
fi

source "${HOME}/.bugsplat.conf"

if [ -z "${BUGSPLAT_USER}" ]
then
    echo "BUGSPLAT_USER must be set in ~/.bugsplat.conf" >> $LOG 2>&1
    exit
fi

if [ -z "${BUGSPLAT_PASS}" ]
then
    echo "BUGSPLAT_PASS must be set in ~/.bugsplat.conf" >> $LOG 2>&1
    exit
fi
fi ## end of skipping ~/.bugsplat.conf

if [ -n "$2" ]
then # caller passed in APP and XCARCHIVE explicitly,
     # instead of making the script find and zip the archive
     APP="$1"
     XCARCHIVE="$2"
     PRODUCT_NAME="$(/usr/libexec/PlistBuddy -c "Print CFBundleExecutable" "${APP}/Contents/Info.plist")"
     # The original script very explicitly expects to find the zipped
     # XCARCHIVE at /tmp/$PRODUCT_NAME.xcarchive.zip -- sigh, should have been
     # another shell variable. Move our XCARCHIVE there.
     mv -v "$XCARCHIVE" "/tmp/$PRODUCT_NAME.xcarchive.zip" > "$LOG" 2>&1
else ## "classic" invocation without APP and XCARCHIVE
DATE=$( /bin/date +"%Y-%m-%d" )
ARCHIVE_DIR="${HOME}/Library/Developer/Xcode/Archives/${DATE}"
ARCHIVE=$( /bin/ls -t "${ARCHIVE_DIR}" | /usr/bin/grep xcarchive | /usr/bin/sed -n 1p )

echo "Archive: ${ARCHIVE}" > $LOG 2>&1

APP="${ARCHIVE_DIR}/${ARCHIVE}/Products/Applications/${PRODUCT_NAME}.app"
fi ## "classic" invocation
APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP}/Contents/Info.plist")
BUGSPLAT_SERVER_URL=$(/usr/libexec/PlistBuddy -c "Print BugsplatServerURL" "${APP}/Contents/Info.plist")
BUGSPLAT_SERVER_URL=${BUGSPLAT_SERVER_URL%/}

UPLOAD_URL="${BUGSPLAT_SERVER_URL}/post/plCrashReporter/symbol/"

echo "App version: ${APP_VERSION}" >> $LOG 2>&1
if [ -z "$2" ]
then ## skip this if XCARCHIVE was explicitly passed
echo "Zipping ${ARCHIVE}" >> $LOG 2>&1

/bin/rm "/tmp/${PRODUCT_NAME}.xcarchive.zip"
cd "${ARCHIVE_DIR}/${ARCHIVE}"
/usr/bin/zip -r "/tmp/${PRODUCT_NAME}.xcarchive.zip" *
cd -
fi ## skipping zipping

UUID_CMD_OUT=$(xcrun dwarfdump --uuid "${APP}/Contents/MacOS/${PRODUCT_NAME}")
UUID_CMD_OUT=$([[ "${UUID_CMD_OUT}" =~ ^(UUID: )([0-9a-zA-Z\-]+) ]] && echo ${BASH_REMATCH[2]})
echo "UUID found: ${UUID_CMD_OUT}" > $LOG 2>&1

echo "Signing into bugsplat and storing session cookie for use in upload" >> $LOG 2>&1

COOKIEPATH="/tmp/bugsplat-cookie.txt"
LOGIN_URL="${BUGSPLAT_SERVER_URL}/browse/login.php"
echo "Login URL: ${LOGIN_URL}"
rm "${COOKIEPATH}"
curl -b "${COOKIEPATH}" -c "${COOKIEPATH}" --data-urlencode "currusername=${BUGSPLAT_USER}" --data-urlencode "currpasswd=${BUGSPLAT_PASS}" "${LOGIN_URL}"

echo "Uploading /tmp/${PRODUCT_NAME}.xcarchive.zip to ${UPLOAD_URL}" >> $LOG 2>&1

curl -i -b "${COOKIEPATH}" -c "${COOKIEPATH}" -F filedata=@"/tmp/${PRODUCT_NAME}.xcarchive.zip" -F appName="${PRODUCT_NAME}" -F appVer="${APP_VERSION}" -F buildId="${UUID_CMD_OUT}" $UPLOAD_URL >> $LOG 2>&1
