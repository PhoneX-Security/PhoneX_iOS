SOURCE_FILE="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

function showUsage() {
        echo "USAGE: sh ${SOURCE_FILE} <file xlsx->csv>"
        echo "EXAMPLE: sh ${SOURCE_FILE} translated.csv"
        echo
}

TARGET_FILE=$1

if [ -z ${TARGET_FILE} ]; then
        echo "ERROR: source file argument missing!"
        showUsage
        exit -1

fi

if [ ! -f ${TARGET_FILE} ]; then
        echo "ERROR: ${TARGET_FILE} does not exist!"
        showUsage
        exit -2
fi

FILE_TO_EXPORT=$(basename "${TARGET_FILE}" .csv)-cleaned.csv


cat ${TARGET_FILE} | awk -v AWK_FILE="${FILE_TO_EXPORT}" \
'{ if (length($0) > 0) print substr($0, 1 length($0) - 1) >> AWK_FILE} END {print "" >> AWK_FILE}';
#'{ if (length($0) > 0) print substr($1, 1, length($0)-2) >> AWK_FILE} END {print "" >> AWK_FILE}';
