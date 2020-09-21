#!/bin/bash

# read the global configuration file autowx2_conf.py via the bash/python configuration parser
# do not change the following three lines
scriptDir="$(dirname "$(realpath "$0")")"
source $scriptDir/basedir_conf.py
source $baseDir/_listvars.sh

###
tempStorage="tle.tmp"

function getData {
    local option link targetFile

    if [ $# != 2 ];
    then
        echo "2 parameters required. No more, no less."
        exit 1
    fi

    link=$1
    targetFile=$2

    if [[ -z "${targetFile}" || -z "${link}" ]];
    then
        echo "Target file and URL link must be set."
        echo "Target file: ${targetFile}"
        echo "URL link: ${link}"
        exit 1
    fi

    wget -r $link -O $TLEDIR/$tempStorage
    if [[ -f $TLEDIR/$tempStorage && "$(cat $TLEDIR/$tempStorage)" != "" ]];
    then
        cat $TLEDIR/$tempStorage > $TLEDIR/$targetFile
    fi
}

TLEDIR=${baseDir}var/tle
mkdir -p $TLEDIR

getData http://www.celestrak.com/NORAD/elements/weather.txt weather.txt

# getData http://www.celestrak.com/NORAD/elements/noaa.txt noaa.txt

getData http://www.celestrak.com/NORAD/elements/amateur.txt amateur.txt

getData http://www.celestrak.com/NORAD/elements/cubesat.txt cubesat.txt

getData http://www.pe0sat.vgnet.nl/kepler/mykepler.txt multi.txt

cat $TLEDIR/*.txt > $TLEDIR/all.txt


echo "$wwwDir"
date
date -R > $wwwDir/keps.tmp
date +"%s" > $wwwDir/kepsU.tmp
echo Updated
