THIRD_PARTY_FOLDER="./third_party"

DEST_FOLDER=".."

# third_party
        LIB_FOLDER=""${DEST_FOLDER}"/third_party"
        rm -rf "${LIB_FOLDER}"
        mkdir "${LIB_FOLDER}"
        cp -r ./third_party/lib "${LIB_FOLDER}"/lib
        INCLUDE=""${LIB_FOLDER}"/include"
        mkdir "${INCLUDE}"
        cp -r "${THIRD_PARTY_FOLDER}"/bdsound/include "${INCLUDE}"/bdsound
        cp -r "${THIRD_PARTY_FOLDER}"/gsm/inc "${INCLUDE}"/gsm
        cp -r "${THIRD_PARTY_FOLDER}"/mp3 "${INCLUDE}"/mp3
        cp -r "${THIRD_PARTY_FOLDER}"/resample/include "${INCLUDE}"/resample
        cp -r "${THIRD_PARTY_FOLDER}"/srtp/include "${INCLUDE}"/srtp
        cp -r "${THIRD_PARTY_FOLDER}"/portaudio/include "${INCLUDE}"/portaudio
        cp -r "${THIRD_PARTY_FOLDER}"/speex/include/speex "${INCLUDE}"/speex 
