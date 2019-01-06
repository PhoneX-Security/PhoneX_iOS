########################################################
#
# must be copied and launched from root of the pjproject
#
########################################################

# DIR= eror because the ./configure looks for ./acongifure
RETURN_DIR="$PWD"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -d "$DIR/_source" ]; then
		echo "ERROR: cannot find _source directory with PJSIP library"
		exit -2	
fi

# Descend to the _source directory, we need to have there current directory due to other
# dependencies, e.g., aconfigure.
cd "${DIR}/_source"

DEST_FOLDER=".."

if [ -z "${DEST_FOLDER}" ]; then
        echo "ERROR: Env var DEST_FOLDER not set! Set it to IOS_PROJECT/dependency/pjproject"
        exit -1
fi

#see _build.sh
declare -a PJ_COMPONENTS=("pjlib" "pjlib-util" "pjnath" "pjmedia" "pjsip")

for PJ_COMPONENT in ${PJ_COMPONENTS[*]}
do
	LIB_FOLDER=""${DEST_FOLDER}"/"${PJ_COMPONENT}""
	rm -rf "${LIB_FOLDER}"
	mkdir "${LIB_FOLDER}"
	cp -r ./"${PJ_COMPONENT}"/include "${LIB_FOLDER}"/include
	cp -r ./"${PJ_COMPONENT}"/lib "${LIB_FOLDER}"/lib
done

cd "${RETURN_DIR}"
