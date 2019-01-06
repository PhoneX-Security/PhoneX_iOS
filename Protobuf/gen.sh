#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Working dir: $DIR"

protoc --proto_path="$DIR" --java_out="$DIR/../src/" "$DIR/filetransfer.proto"
protoc --proto_path="$DIR" --java_out="$DIR/../src/" "$DIR/push.proto"
protoc --proto_path="$DIR" --java_out="$DIR/../src/" "$DIR/rest.proto"
protoc --proto_path="$DIR" --java_out="$DIR/../src/" "$DIR/message.proto"

echo "[  DONE  ]"


