#!/usr/bin/env bash
###################################################################
#
# must be copied and launched from root of the pjproject
#
# copy to root of the pjsip project
# configure config_state.h (TODO the script should do it in future)
# see https://trac.pjsip.org/repos/wiki/Getting-Started/iPhone
# at least:
# #define PJ_CONFIG_IPHONE 1
# #include <pj/config_site_sample.h>
#
#  - Patch source files.
#  - Copy patched source files to architecture dependent directories. 
#  - Compile in each directory separately (benefit - one change = easy recompilation)
#
###################################################################
function myreadlink2() {
  (
        cd $1       # or  cd ${1%/*}
        echo $PWD   # or  echo $PWD/${1##*/}
  )
}

########################### VARIABLES ########################################

# Set build type: release/debug.
PEX_BUILD=${PEX_BUILD:-"release"}

# Debug switch
[[ "${PEX_BUILD}" == "debug" ]]
PEX_IS_DEBUG=$?

# Allowed values test
if [[ "${PEX_BUILD}" != "release" && "${PEX_BUILD}" != "debug" ]]; then
	echo "Error: PEX_BUILD has invalid (unknown) value: ${PEX_BUILD}"
	exit -99
fi

echo "Going to build: ${PEX_BUILD}"

# DIR= eror because the ./configure looks for ./acongifure
RETURN_DIR="$PWD"
UDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="${UDIR}/_source"

# Architecture to take includes from
INCARCH="arm64"

declare -a ARCHITECTURES=("i386" "x86_64" "armv7" "armv7s" "arm64")
declare -a SIMULATOR_ARCHITECTURES=("i386" "x86_64")
declare -a IPHONE_ARCHITECTURES=("armv7" "armv7s" "arm64")
declare -a PJ_COMPONENTS=("pjlib" "pjlib-util" "pjnath" "pjmedia" "pjsip")

cd "${UDIR}"
if [ ! -d "${DIR}" ]; then
		echo "> ERROR: cannot find _source directory with PJSIP library: ${DIR}"
		exit -2	
fi

# Check for rsync.
which rsync 2>/dev/null > /dev/null
RSYNC_OK=$?
if [[ $RSYNC_OK != 0 ]]; then
    echo "> Error: rsync was not found, please install it".
    exit 3
fi

# OpenSSL library path. Resolves to absolute path.
OPENSSL=`myreadlink2 "../openssl-ios"`
if [ -z "${OPENSSL}" ]; then
        echo "> ERROR: Env var OPENSSL not set! Set OPENSSL that OPENSSL/include and OPENSSL/lib exist"
        exit -1
fi

if [ ! -d "${OPENSSL}" ]; then
		echo "> ERROR: OpenSSL library directory was not found! Dir:[$OPENSSL]"
		exit -3
fi

# Copy configuration header file to relevant destinations.
CONFIG_SITE="${UDIR}/configuration/config_site.h" 
if [ ! -f "${CONFIG_SITE}" ]; then
		echo "> ERROR: config_site.h is missing [${CONFIG_SITE}]"
		exit -4
fi

mkdir -p "${DIR}/pjlib/include/pj" 2>/dev/null >/dev/null
mkdir -p "${UDIR}/pjlib/include/pj/" 2>/dev/null >/dev/null
rsync --update "${CONFIG_SITE}" "${DIR}/pjlib/include/pj/config_site.h" && \
rsync --update "${CONFIG_SITE}" "${UDIR}/pjlib/include/pj/config_site.h" 
if [ $? -ne 0 ]; then
	echo "> config_site.h could not be copied to the PJSIP structure, please verify it."
	exit -5
fi

# Apply quilt patches
if [ ! -f .patched_sources ]; then
	echo "> Going to apply all quilt patches"
	quilt push -a && touch .patched_sources 
	if [ $? -ne 0 ]; then
		echo "> Cannot apply quilt patches, please verify compatibility. You might updated PJSIP without refreshing patches."
		exit -6
	fi
fi

# Additional definitions for build process.
export BUILD_OUTPUT_DIR="_output"
export PLATFORMS_PATH="/Applications/Xcode.app/Contents/Developer/Platforms"
export SIMULATOR_DEVPATH=""${PLATFORMS_PATH}"/iPhoneSimulator.platform/Developer"
export IPHONE_DEVPATH=""${PLATFORMS_PATH}"/iPhoneOS.platform/Developer"

# OPENSSL="/Users/eldred/work/project/Phonex/ios/app/repo/dependency/openssl-ios"
# according to projects README -O2 and -DNDEBUG ale implicit
OPTIMIZE_FLAGS="-O2"
if [ "${PEX_BUILD}" == "debug" ]; then
	OPTIMIZE_FLAGS="-O0 -g"	
fi

export COMMON_CFLAGS="${OPTIMIZE_FLAGS} -Wno-unused-label -I"${OPENSSL}"/include -miphoneos-version-min=8.0"
export COMMON_LDFLAGS="${OPTIMIZE_FLAGS} -L"${OPENSSL}"/lib -lcrypto -lssl -miphoneos-version-min=8.0"
export SIMULATOR_COMMON_CFLAGS=""${COMMON_CFLAGS}" "-mios-simulator-version-min=7.1""
export SIMULATOR_COMMON_LDFLAGS=""${COMMON_LDFLAGS}" "-mios-simulator-version-min=7.1""
export SIMULATOR_32_CFLAGS=""${SIMULATOR_COMMON_CFLAGS}" -m32"
export SIMULATOR_32_LDFLAGS=""${SIMULATOR_COMMON_LDFLAGS}" -m32"
export SIMULATOR_64_CFLAGS=""${SIMULATOR_COMMON_CFLAGS}" -m64"
export SIMULATOR_64_LDFLAGS=""${SIMULATOR_COMMON_LDFLAGS}" -m64"
export THIRD_PARTY_FOLDER="third_party"

DEST_FOLDER="${UDIR}"
LIPOLIBS="${UDIR}/_libs"

# TODO extract from ARCHITECTURES

# FOR TESTING PURPOSES (SHORTER RUNNING TIME)
# Comment the x86_64 architecture on the bottom
#declare -a ARCHITECTURES=("i386")
#declare -a SIMULATOR_ARCHITECTURES=("i386")
#declare -a IPHONE_ARCHITECTURES=()
################################################################################

# Outputs architecture directory.
function getArchDir() {
    if (( $PEX_IS_DEBUG == 0 )); then
        echo "${DIR}_dbg_$1"
    else
        echo "${DIR}_$1"
    fi
}

#
# clear builded libs in current build directory.
#
function clearLibs() {
	for PJ_COMPONENT in ${PJ_COMPONENTS[*]}
        do
        	rm -rf ./"${PJ_COMPONENT}"/lib/*
        done

	rm -rf "./${THIRD_PARTY_FOLDER}"/lib/*
}

#
# 1 architecture name
# 2 folder path
# 3 destination folder path
#
function storeArchitecture() {
	FOLDER_PATH="${2}"
	DEST_PATH="${3}"
	for FILE_PATH in ${FOLDER_PATH}/*; do
       if [ ${FILE_PATH: -2} == ".a" ] ;then
            FILE=$(basename "${FILE_PATH}")
            FILE_NAME="${FILE%.*}"

            DEST_FOLDER_PATH="${DEST_PATH}/${FILE_NAME}"
            if ! [ -d "${DEST_FOLDER_PATH}" ] ; then
                    mkdir -p "${DEST_FOLDER_PATH}"
            fi

            DESTINATION=""${DEST_FOLDER_PATH}"/"${FILE_NAME}"_"${1}".a"
            mv "${FILE_PATH}" "${DESTINATION}"
            echo "> INFOLOG: moving "${FILE_PATH}" to "${DESTINATION}""
       fi
    done
}

#
# 1 architecture name
# 
function buildArchitecture() {
	MYDIR=$(pwd)
    export ARCH="-arch "${1}""

    # Configure only if needed.
    if [ ! -f "${MYDIR}/.phonex.configured" ]; then
    	echo "> Architecture not configured, going to configure it."
    	
    	# Remove depend files - temporary build files.
    	find ${MYDIR} -type f -name '*.depend' -exec /bin/rm {} \;
    	
    	# Configure project for a given architecture.
		"${MYDIR}"/configure-iphone --enable-ssl --with-ssl="${OPENSSL}"
		if [ $? -ne 0 ]; then
			echo "> CONFIGURE FAILED"
			exit -1
		fi
		
		touch "${MYDIR}/.phonex.configured"
	fi
	
	# Make dependencies, if needed.
	if [ ! -f "${MYDIR}/.phonex.dep" ]; then
		echo "> DEP not build, going to build it."
		
		make dep
		if [ $? -ne 0 ]; then
				echo "MAKE FAILED"
				exit -2
		fi
		touch "${MYDIR}/.phonex.dep"
	fi
	
	# Final make.
	echo "> Going to make"
	make
	if [ $? -ne 0 ]; then
			echo "MAKE FAILED"
			exit -2
	fi

	for PJ_COMPONENT in ${PJ_COMPONENTS[*]}
	do
		FOLDER_PATH=""${MYDIR}"/"${PJ_COMPONENT}"/lib"
		storeArchitecture "${1}" "${FOLDER_PATH}" "${LIPOLIBS}/${PJ_COMPONENT}/lib"
	done

	storeArchitecture "${1}" "${MYDIR}/${THIRD_PARTY_FOLDER}/lib" "${LIPOLIBS}/${THIRD_PARTY_FOLDER}/lib"
}

#
# 1 folder path
#
lipoLib() {
	FOLDER_PATH="${1}"
	DESIRED_UNIVERSAL_LIB_SUFFIX="-arm-apple-darwin9.a"
	TEST_ARCHITECTURE=${ARCHITECTURES[0]}
	TEST_ARCHITECTURE_STRING="-${TEST_ARCHITECTURE}-"
	echo "Lipo dir: $FOLDER_PATH"

	# Find all libraries in the given folder.
	# Convention is: libpj-arm64-apple-darwin_ios
	find ${FOLDER_PATH} -maxdepth 1 -type d -name "*${TEST_ARCHITECTURE_STRING}*" -print0 |
    while IFS= read -r -d $'\0' FILE_PATH; do
   		LIPO_TASK="lipo"
   		FILE_BASE=$(basename "${FILE_PATH}")
        echo "FILE_PATH: $FILE_PATH"
        echo "FILE_BASE: $FILE_BASE"

        # Extract library name, trailing rubbish.
        # Thus "libpj" and "apple-darwin_ios"
        LIB_NAME=${FILE_BASE%$TEST_ARCHITECTURE_STRING*}
		BLAH_SUFFIX=${FILE_BASE#*$TEST_ARCHITECTURE_STRING}
		echo "Libname: $LIB_NAME, suffix: $BLAH_SUFFIX"

		# LIPO resulting universal library
		for i in ${ARCHITECTURES[*]}
		do
			LIBFILE=${FOLDER_PATH}"/"${LIB_NAME}"-"$i"-"${BLAH_SUFFIX}"/"${LIB_NAME}"-"$i"-"${BLAH_SUFFIX}"_"$i".a"
			echo "LIB FILE: $LIBFILE"

			LIPO_TASK=" "${LIPO_TASK}" -arch "${i}" ${LIBFILE}"
		done

		LIPO_TASK=""${LIPO_TASK}" -create -output "${FOLDER_PATH}"/"${LIB_NAME}${DESIRED_UNIVERSAL_LIB_SUFFIX}
		echo "final LIPO_TASK: "${LIPO_TASK}""
		eval "${LIPO_TASK}"
		if [ $? -ne 0 ]; then
			echo "LIPO FAILED"
			exit -3
		fi
    done
}

#
# Starts LIPO process - assembling libraries with different architectures to universal one.
#
function lipoBuild() {
	for PJ_COMPONENT in ${PJ_COMPONENTS[*]}
	do
		FOLDER_PATH="${LIPOLIBS}/${PJ_COMPONENT}/lib"
		lipoLib "${FOLDER_PATH}"
	done

	lipoLib "${LIPOLIBS}/${THIRD_PARTY_FOLDER}/lib"
}

#
# Copies include header files and libraries to export directory used by project.
#
function copyDist() {
	# Source directory to use include files from 
	INCDIR=$(getArchDir $INCARCH)

	if [ ! -d "${INCDIR}" ]; then
                echo "> ERROR: cannot find ${INCDIR} directory with PJSIP library to build include files"
                exit -2
	fi

	for PJ_COMPONENT in ${PJ_COMPONENTS[*]}
	do
		LIB_FOLDER=""${DEST_FOLDER}"/"${PJ_COMPONENT}""
		echo $LIB_FOLDER
		
		#rm -rf "${LIB_FOLDER}"
		mkdir -p "${LIB_FOLDER}"
		rsync -av --delete "${INCDIR}/${PJ_COMPONENT}"/include/ "${LIB_FOLDER}"/include/
		rsync -av --delete "${LIPOLIBS}/${PJ_COMPONENT}"/lib/ "${LIB_FOLDER}"/lib/
	done

	# third_party
	LIB_FOLDER="${DEST_FOLDER}/third_party"
	#rm -rf "${LIB_FOLDER}"
	mkdir -p "${LIB_FOLDER}"
	rsync -av --delete "${LIPOLIBS}/third_party/lib/" "${LIB_FOLDER}/lib/"
	
	INCLUDE="${LIB_FOLDER}/include"
	mkdir -p "${INCLUDE}"
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/bdsound/include/ "${INCLUDE}"/bdsound/
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/gsm/inc/ "${INCLUDE}"/gsm/
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/mp3/ "${INCLUDE}"/mp3/
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/resample/include/ "${INCLUDE}"/resample/
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/srtp/include/ "${INCLUDE}"/srtp/
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/portaudio/include/ "${INCLUDE}"/portaudio/
	rsync -av --delete "${INCDIR}/${THIRD_PARTY_FOLDER}"/speex/include/speex/ "${INCLUDE}"/speex/
}

#
# Builds architecture in its directory.
#
function buildArchitectureSeparately () {
    curArch=$1
    ARCHDIR=$(getArchDir $curArch)
    
    echo -e "\n\n\n"
    echo "================================================================================"
    echo " - ARCH: ${curArch}"
    echo "================================================================================"
    echo "> Copying architecture $curArch to $ARCHDIR/"
    rsync -a --update --exclude '*.o' -v "${DIR}/" "${ARCHDIR}/"
    
    # Clear old libraries, if needed.
    cd "${ARCHDIR}"
    # clearlib
    
    echo "> Building architecture ${curArch} in directory: ${ARCHDIR}"
    cd "${ARCHDIR}"
    buildArchitecture $curArch
}


####################### BUILD ###########################
# Sanitize source directory, remove build artifacts from DIR
echo "> Cleaning output source dir."
/bin/rm -rf "${DIR}/build/output"
for PJ_COMPONENT in ${PJ_COMPONENTS[*]}
    do
        /bin/rm -rf "${DIR}/${PJ_COMPONENT}"/build/output
    done

/bin/rm -rf "./${THIRD_PARTY_FOLDER}"/build/output

############# SIMULATOR #####################
export DEVPATH=${SIMULATOR_DEVPATH}

############ i386 ############################
export CFLAGS="${SIMULATOR_32_CFLAGS}"
export LDFLAGS="${SIMULATOR_32_LDFLAGS}"
buildArchitectureSeparately "i386"

############ x86_64 #########################
export CFLAGS="${SIMULATOR_64_CFLAGS}"                   
export LDFLAGS="${SIMULATOR_64_LDFLAGS}" 
buildArchitectureSeparately "x86_64"

############## IPHONE #######################
export DEVPATH=${IPHONE_DEVPATH}

export CFLAGS="${COMMON_CFLAGS}"
export LDFLAGS="${COMMON_LDFLAGS}"
for i in "${IPHONE_ARCHITECTURES[@]}"
do
	buildArchitectureSeparately "${i}"
done

############## LIPO ########################
lipoBuild

copyDist

# Un-apply patches.
#cd $UDIR
#echo "Going to revert quilt patches."
#if [ -f .patched_sources ]; then
#	quilt pop -a && rm .patched_sources;
#
#	if [ $? -ne 0 ]; then
#		echo "Quilt unpatching went wrong... Please, fix it."
#		exit -6
#	fi
#fi

# Return to calling directory.
cd "${RETURN_DIR}"
echo "> DONE for [${PEX_BUILD}]"
