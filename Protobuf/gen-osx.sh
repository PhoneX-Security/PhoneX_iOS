#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC="$DIR/newproto"
DST="$DIR/../Phonex/Source/Specific/Protobuf"
NOC="\033[0m"
GREEN="\033[0;32m"

echo "Working dir: $DIR"

which protoc > /dev/null 2> /dev/null
if (($?!=0)); then
    echo "You don't have Protocol buffers installed."
    echo "https://developers.google.com/protocol-buffers"
    exit 1
fi

if [ ! -f /usr/local/bin/protoc-gen-objc ]; then
    echo "You don't have objective C plugin for Protocol buffers installed."
    echo "https://github.com/alexeyxo/protobuf-objc"
fi

# Refactor proto files
echo -e "$GREEN[+]$NOC Going to refactor proto files."
bash pytools/refactorProtoFiles.sh
if (($?!=0)); then
    echo -e "Failed"
    exit 2
fi
echo -e "$GREEN[+]$NOC Refactoring done."

# Convert each proto file found.
while IFS= read -d $'\0' -r file ; do
    protoc --plugin=/usr/local/bin/protoc-gen-objc --proto_path="$SRC" --objc_out="$DST" "$file"
done < <(find "$SRC" -maxdepth 1 -type f -name '*.proto' -print0)

#protoc --plugin=/usr/local/bin/protoc-gen-objc --proto_path="$DIR" --objc_out="$DST" "$DIR/filetransfer.proto"
#protoc --plugin=/usr/local/bin/protoc-gen-objc --proto_path="$DIR" --objc_out="$DST" "$DIR/push.proto"
#protoc --plugin=/usr/local/bin/protoc-gen-objc --proto_path="$DIR" --objc_out="$DST" "$DIR/rest.proto"
#protoc --plugin=/usr/local/bin/protoc-gen-objc --proto_path="$DIR" --objc_out="$DST" "$DIR/message.proto"

echo "[  DONE  ]"


