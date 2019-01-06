#  
#
#
function myreadlink2() {
  (
        cd $1       # or  cd ${1%/*}
        echo $PWD   # or  echo $PWD/${1##*/}
  )
}


RETURN_DIR="$PWD"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "- DIR = ${DIR}"
cd "${DIR}"
export SRC_DIR=""${DIR}"/sources/zrtp"

export OPENSSL=`myreadlink2 "../openssl-ios"`
echo "- OPENSSL = ${OPENSSL}"

export PJ_PROJECT=`myreadlink2 "../pjproject"`
echo "- PJ_PROJECT = ${PJ_PROJECT}"

export BUILD_DIR=${DIR}/_output
mkdir ${BUILD_DIR}
echo "BUILD_DIR = ${BUILD_DIR}"

export OUTPUT_FILE_BASE="libzrtp"

####################### ACTUAL BUILDING  ##########################

CXXBUU="${CXXFLAGS} -Wall -O2 -DNDEBUG -DDYNAMIC_TIMER=1"
LDBUU="${LDFLAGS}"
CXXBU="${CXXFLAGS}"
LDBU="${LDFLAGS}"
export PLATFORMS_PATH="/Applications/Xcode.app/Contents/Developer/Platforms"
export SIMULATOR_DEVPATH=""${PLATFORMS_PATH}"/iPhoneSimulator.platform/Developer"
export IPHONE_DEVPATH=""${PLATFORMS_PATH}"/iPhoneOS.platform/Developer"
declare -a ARCHITECTURES=("i386" "x86_64" "armv7" "armv7s" "arm64")
declare -a SIMULATOR_ARCHITECTURES=("i386" "x86_64")
declare -a IPHONE_ARCHITECTURES=("armv7" "armv7s" "arm64")

export MIN_VERSION="7.1"

INCLUDE_PATH=""${DIR}":"${DIR}"/zrtp:"${DIR}"/srtp:"${DIR}"/zrtp/libzrtpcpp"
export CPLUS_INCLUDE_PATH="${INCLUDE_PATH}"
echo "CPLUS_INCLUDE_PATH = "${CPLUS_INCLUDE_PATH}""
export C_INCLUDE_PATH="${INCLUDE_PATH}"
echo "C_INCLUDE_PATH = "${C_INCLUDE_PATH}""

################## REMOVE OLD LIBS ###################

echo "REMOVING OLD LIBRARIES"
for FILE in ${BUILD_DIR}/*
do
	rm "${FILE}"
done

######################## BUILD ###########################

#
# 1 - exit code
#
function exitWithCode {
	cd ${RETURN_DIR}
	exit $1
}

function callMake() {
	
	# cp _Makefile "${SRC_DIR}"/_Makefile
	# cd "${SRC_DIR}"

	make -f "${DIR}"/_Makefile clean
	if [ $? -ne 0 ]; then
                        echo "MAKE CLEAN FAILED"
                        exitWithCode -2
        fi

	make -f "${DIR}"/_Makefile
	if [ $? -ne 0 ]; then
                        echo "MAKE FAILED"
                        exitWithCode -1
        fi

	make -f "${DIR}"/_Makefile clean
	if [ $? -ne 0 ]; then
                        echo "MAKE CLEAN FAILED"
                        exitWithCode -2
        fi

	# cd "${DIR}"
}

export AR=ar
# export AR="${TCPATH}/usr/bin/libtool"
# export AR=ld
# export AR=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/ar

### SIMULATOR
export DEVPATH="${SIMULATOR_DEVPATH}"
export TCPATH=""${DEVPATH}"/../../../Toolchains/XcodeDefault.xctoolchain"
export SDKPATH=""${DEVPATH}"/SDKs/iPhoneSimulator.sdk"
export CXXBU=""${CXXBUU}" -DPJ_SDK_NAME=\"\\\"`basename $SDKPATH`\\\"\" -isysroot ${SDKPATH} -mios-simulator-version-min="${MIN_VERSION}""
export LDBU=""${LDBUU}" -isysroot "${SDKPATH}" -mios-simulator-version-min="${MIN_VERSION}""

### i386
export ARCH="i386"
export CXXFLAGS=""${CXXBU}" -m32"
export LDFLAGS=""${LDBU}" -m32"
callMake

### x86_64
export ARCH="x86_64"
export CXXFLAGS=""${CXXBU}" -m64"
export LDFLAGS=""${LDBU}" -m64"
callMake

### IPHONE
export DEVPATH="${IPHONE_DEVPATH}"
export TCPATH=""${DEVPATH}"/../../../Toolchains/XcodeDefault.xctoolchain"
export SDKPATH=""${DEVPATH}"/SDKs/iPhoneOS.sdk"
export CXXBU=""${CXXBUU}" -DPJ_SDK_NAME=\"\\\"`basename $SDKPATH`\\\"\" -isysroot ${SDKPATH} -miphoneos-version-min="${MIN_VERSION}""
export LDBU=""${LDBUU}" -isysroot "${SDKPATH}" -miphoneos-version-min="${MIN_VERSION}""
### ARMs
export CXXFLAGS="${CXXBU}"
export LDFLAGS="${LDBU}"
for i in "${IPHONE_ARCHITECTURES[@]}"
do
	export ARCH="${i}"
	callMake
done

### LIPO

LIPO_TASK="lipo"
for i in ${ARCHITECTURES[*]}
do
	LIPO_TASK=""${LIPO_TASK}" -arch "${i}" "${BUILD_DIR}"/"${OUTPUT_FILE_BASE}"_"${i}".a"
done
LIPO_TASK=""${LIPO_TASK}" -create -output "${BUILD_DIR}"/"${OUTPUT_FILE_BASE}".a"
echo "final LIPO_TASK: "${LIPO_TASK}""
eval "${LIPO_TASK}"
if [ $? -ne 0 ]; then
	echo "LIPO FAILED"
	exitWithCode -3
fi

#
# END
#	
exitWithCode 0

