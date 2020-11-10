#!/bin/sh

USAGE="Usage: `basename $0` <sandboxRoot>"

if [ $# != 1 ] 
	then
		echo ${USAGE}
		exit 0
fi

cd tests
MATLABCMD="mw -using $1 matlab -r driver"

${MATLABCMD}
