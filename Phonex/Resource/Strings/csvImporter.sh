SOURCE_FILE="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
LOCALE_DIR_SUFIX=".lproj"
LOCALE_FILE_NAME="InfoPlist.strings"

function showUsage() {
        echo "USAGE: sh ${SOURCE_FILE} <translated csv file> <target locale>"
        echo "EXAMPLE: sh ${SOURCE_FILE} cs-to-pl_translated.txt pl"
        echo "i.e. en${LOCALE_DIR_SUFIX}/${LOCALE_FILE_NAME}"
        echo
}

FROM_FILE=$1

if [ -z ${FROM_FILE} ]; then
        echo "ERROR: source file argument missing!"
        showUsage
        exit -1

fi

if [ ! -f ${FROM_FILE} ]; then
        echo "ERROR: ${FROM_FILE} does not exist!"
        showUsage
        exit -2
fi

LOCALE=$2

if [ -z ${LOCALE} ]; then
        echo "ERROR: locale argument missing!"
        showUsage
        exit -3
fi

LOCALE_DIR="${LOCALE}${LOCALE_DIR_SUFIX}"

if [ ! -d ${LOCALE_DIR} ]; then

	mkdir ${LOCALE_DIR}
	
	if [ $? -ne 0 ]; then
        	echo "ERROR: unable to create folder ${LOCALE_DIR}!"
        	showUsage
        	exit -4
	fi
fi

LOCALE_FILE="${LOCALE_DIR}/${LOCALE_FILE_NAME}"

if [ -f ${LOCALE_FILE} ]; then
	rm ${LOCALE_FILE}

	if [ $? -ne 0 ]; then
		echo "ERROR: unable to delete file ${LOCALE_FILE}!"
	        showUsage
	        exit -5
	fi
fi

FILE_TO_EXPORT=${LOCALE_FILE}
DELIMITER="|"
	
cat ${FROM_FILE} | awk -v AWK_FILE="${FILE_TO_EXPORT}" -F "${DELIMITER}" \
'{ if (length($1) > 0) print "\""$1"\"" " = " "\""$3"\";" >> AWK_FILE} END {print "" >> AWK_FILE}';
