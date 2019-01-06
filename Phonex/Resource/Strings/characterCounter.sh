SOURCE_FILE="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
LOCALE_DIR_SUFIX=".lproj"
LOCALE_FILE_NAME="InfoPlist.strings"

function showUsage() {
	echo "USAGE: sh ${SOURCE_FILE} <locale that 'locale${LOCALE_DIR_SUFIX}/${LOCALE_FILE_NAME}' exists>"
	echo "EXAMPLE: sh ${SOURCE_FILE} en"
	echo "i.e. en${LOCALE_DIR_SUFIX}/${LOCALE_FILE_NAME}"
	echo
}

LOCALE=$1

if [ -z ${LOCALE} ]; then
	echo "ERROR: locale argument missing!"
	showUsage
        exit -1
fi

LOCALE_DIR="${LOCALE}${LOCALE_DIR_SUFIX}"

if [ ! -d ${LOCALE_DIR} ]; then
	echo "ERROR: ${LOCALE_DIR} does not exist!"
	showUsage
        exit -2
fi

LOCALE_FILE="${LOCALE_DIR}/${LOCALE_FILE_NAME}"

if [ ! -f ${LOCALE_FILE} ]; then
        echo "ERROR: ${LOCALE_FILE} does not exist!"
        showUsage
        exit -3
fi

FILE_TO_PROCESS=${LOCALE_FILE}

COUNT=0
cat ${FILE_TO_PROCESS} | awk -F '"' '{COUNT+=length($4)} END {print COUNT}';
