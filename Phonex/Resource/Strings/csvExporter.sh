SOURCE_FILE="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
LOCALE_DIR_SUFIX=".lproj"
LOCALE_FILE_NAME="InfoPlist.strings"

function showUsage() {
	echo "USAGE: sh ${SOURCE_FILE} <locale> <target locale>"
	echo "EXAMPLE: sh ${SOURCE_FILE} en pl"
	echo "i.e. en${LOCALE_DIR_SUFIX}/${LOCALE_FILE_NAME}"
	echo
}

LOCALE=$1

if [ -z ${LOCALE} ]; then
	echo "ERROR: locale argument missing!"
	showUsage
        exit -1
fi

TARGET_LOCALE=$2

if [ -z ${TARGET_LOCALE} ]; then
	echo "ERROR: target locale argument missing!"
	showUsage
        exit -2
fi

LOCALE_DIR="${LOCALE}${LOCALE_DIR_SUFIX}"

if [ ! -d ${LOCALE_DIR} ]; then
	echo "ERROR: ${LOCALE_DIR} does not exist!"
	showUsage
        exit -3
fi

LOCALE_FILE="${LOCALE_DIR}/${LOCALE_FILE_NAME}"

if [ ! -f ${LOCALE_FILE} ]; then
        echo "ERROR: ${LOCALE_FILE} does not exist!"
        showUsage
        exit -4
fi

FILE_EXPORT="${LOCALE}-to-${TARGET_LOCALE}.csv"

if [ -f ${FILE_EXPORT} ]; then

	rm "${FILE_EXPORT}"

	if [ $? -ne 0 ]; then
		echo "ERROR: Canno remove previous ${FILE_EXPORT}"
	fi
fi

FILE_TO_PROCESS=${LOCALE_FILE}
DELIMITER="|"

echo "INTERNAL NAME (DO NOT MODIFY)${DELIMITER}ORIGINAL EXPRESSION (${LOCALE})${DELIMITER}TRANSLATION (${TARGET_LOCALE})" > ${FILE_EXPORT}

cat ${FILE_TO_PROCESS} | awk -v AWK_FILE="${FILE_EXPORT}" -F '"' \
'{ if (length($2) > 0) print $2 "'"$DELIMITER"'" $4 "'"$DELIMITER"'" >> AWK_FILE} END {print "" >> AWK_FILE}';
