#!/bin/bash
UDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
find "${UDIR}" -type d -name '_source_*' -maxdepth 1 -exec bash -c 'PTH={}; echo -e "\n\nCleaning ${PTH}"; cd $PTH; make clean; cd ..' \;
find "${UDIR}" -type f -name '.phonex.dep' -exec bash -c 'PTH={}; echo -e "\nDeleting dep file $PTH"; /bin/rm $PTH' \;
find "${UDIR}" -type f -name '.phonex.configured' -exec bash -c 'PTH={}; echo -e "\nDeleting config file $PTH"; /bin/rm $PTH' \;
find "${UDIR}" -type d -name 'build' -exec bash -c 'PTH={}; echo -e "\nDeleting output build files $PTH/output"; /bin/rm -rf $PTH/output' \;
