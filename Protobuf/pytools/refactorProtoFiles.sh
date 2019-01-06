#!/bin/bash

CDIR=`pwd`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NEWDIR="$DIR/../newproto/"
SRCDIR="$DIR/.."
NOC="\033[0m"
GREEN="\033[0;32m"

if [ ! -d "$NEWDIR" ]; then
    mkdir "$NEWDIR"
fi

cd "$DIR"
echo -e "$GREEN[+]$NOC Refactoring Protocol Buffers messages - prefixization"

while IFS= read -d $'\0' -r file ; do
    python "$DIR/prefixize.py" -o "$NEWDIR" -p "PEXPb" -v 1 -s 1 "$file"
done < <(find "$SRCDIR" -maxdepth 1 -type f -name '*.proto' -print0)

echo -e "$GREEN[=]$NOC DONE"
cd "$CDIR"
exit 0

