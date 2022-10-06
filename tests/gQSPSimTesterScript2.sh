#!/bin/sh

USAGE="Usage: `basename $0` <version e.g. BR2022ad>"

if [ $# != 1 ] 
	then
		echo ${USAGE}
		exit 0
fi

MATLABCMD="mw -using $1 matlab -r MW_testDriver"

${MATLABCMD}
