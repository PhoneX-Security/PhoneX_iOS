#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC=$DIR/../../../pjproject.gitsvn
DST=$DIR/_source

echo "Source PJSIP:      $SRC"
echo "Destination PJSIP: $DST"

echo "Deleting all directories in DST"
find $DST -type d -mindepth 1  -maxdepth 1 -not -name '.idea' -exec /bin/rm -rf {} \;
find $DIR -type f -name '.phonex.configured' -exec /bin/rm -rf {} \;



