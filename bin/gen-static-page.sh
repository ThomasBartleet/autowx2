#!/bin/bash

# loop over dirs, crate list of files, generates static file

# disable the warning
# shellcheck disable=SC2034

# read the global configuration file autowx2_conf.py via the bash/python configuration parser
# do not change the following three lines
scriptDir="$(dirname "$(realpath "$0")")"
source $scriptDir/basedir_conf.py
source $baseDir/_listvars.sh

################## FINE TUNING #####################

# $recordingDir - real path on the system
# $wwwRootPath/recordings/logs/ - www path

# static values for tests
# imgdir=/home/filips/github/autowx2/recordings/noaa/img/2018/09/08/
# fileNameCore="20180908-1626_NOAA-19"
# wwwDir="/home/filips/github/autowx2/var/www/"


noaaDir=$recordingDir/noaa
meteorDir=$recordingDir/meteor

dirList="$wwwDir/noaa_dirlist.tmp"
htmlTemplate="$wwwDir/index.tpl"
htmlOutput="$wwwDir/index.html"
htmlOutputTable="$wwwDir/table.html"

currentDate=$(date -R)
echo $currentDate
echo "" > $dirList


##### keplers updated? #####
lastkeps=$(cat "$wwwDir/keps.tmp")
lastkepsU=$(cat "$wwwDir/kepsU.tmp")

keplerDays=$(echo "(($(date +"%s") - $lastkepsU ) / (60*60*24))" | bc )
echo $keplerDays
if [ $keplerDays -le 7 ]; 
then
  keplerInfo="<span class='badge badge-pill badge-success'>OK</span>"
else
  keplerInfo="<span class='badge badge-pill badge-danger'>outdated</span>"
fi

echo "lastkeps: $lastkeps"

keplerInfo="Keplers last updated: $lastkeps ($keplerDays days old) $keplerInfo<br />"

##### autowx2 uptime ########

autowxStart=$(cat "$wwwDir/start.tmp")

autowxUptimeH=$(echo "(($(date +"%s") - $autowxStart ) / (60*60))" | bc )
autowxUptimeD=$(echo "(($(date +"%s") - $autowxStart ) / (60*60*24))" | bc )

echo $autowxUptimeH

autowxUptime="autowx2 uptime: $autowxUptimeH h (~$autowxUptimeD d)<br />"

### short list of next passes

shortlistofnextpassess="<br/>Next passes: $(cat "$wwwDir/nextpassshort.tmp")<br />"

function echoSetValueFor {
  echo "Please set an appropriate value for ${1}."
}

function generateGallery {
  local loopVar satelliteDirectory lastRecordingFile sectionTitle howManyToday
  local lastDir lastLog indexFile lastDateTime lastDate lastTime imagesHtml

  for loopVar in "$@";
  do
    # Parameters need to come in the format [--NAME=VALUE], so that it becomes
    # more readable.
    local parameterName parameterValue
    parameterName=$(echo ${loopVar} | cut -d "=" -f 1)
    parameterValue=$(echo ${loopVar} | cut -d "=" -f 2-)

    case "${parameterName}" in
      "--satDir")
        satelliteDirectory=$parameterValue
        ;;

      "--lastRecFile")
        lastRecordingFile=$parameterValue
        ;;
        
      "--title")
        sectionTitle=$parameterValue
        ;;

      "--imagesHtml")
        imagesHtml=$parameterValue
        ;;

      *)
        echo "Invalid parameter option: ${parameterName}"
        ;;
    esac
  done

  # Make sure there are values for each parameter.
  if [[ "${satelliteDirectory}" == "" || ! -d $satelliteDirectory ]];
  then
    echo "Invalid satellite directory: ${satelliteDirectory}"
    echoSetValueFor "--satDir"
  elif [ "${sectionTitle}" == "" ];
  then
    echo "Invalid section title: ${sectionTitle}"
    echoSetValueFor "--title"
  elif [[ "${lastRecordingFile}" == "" || ! -f $wwwDir/$lastRecordingFile ]];
  then
    echo "Invalid last recording file: ${lastRecordingFile}"
    echo "Full path tried: ${wwwDir}/${lastRecordingFile}"
    echoSetValueFor "--lastRecFile"
  elif [ "${imagesHtml}" == "" ];
  then
    echo "Invalid images list: ${imagesHtml}"
    echoSetValueFor "--imagesHtml"
  fi

  #  Start generating HTML file
  
  howManyToday=$(ls $satelliteDirectory/img/$(date +"%Y/%m/%d")/*.log 2> /dev/null| wc -l)
  lastDir=$(dirname $(cat $wwwDir/$lastRecordingFile))
  lastLog=$(basename $(cat $wwwDir/$lastRecordingFile))

  # Generate title
  echo "<h2>${sectionTitle}</h2>" >> $dirList
  echo "<h4>Recent pass</h4>" >> $dirList
  if [ $lastLog ];
  then
    # Get date and time of last recording
    lastDateTime=$(echo $lastLog | cut -d "_" -f 1)
    lastDate=$(echo $lastDateTime | cut -d "-" -f 1)
    lastTime=$(echo $lastDateTime | cut -d "-" -f 2)
    echo "<h6>($lastDate , $lastTime)</h6>" >> $dirList
  fi
  
  # Generate images
  echo "<a href='$lastDir/index.html'>" >> $dirList
  echo "${imagesHtml}" >> $dirList
  echo "</a>" >> $dirList
  echo "<p></p>" >> $dirList

  # Generate archive
  echo "<h4>Archive</h4>" >> $dirList
  echo "<ul>" >> $dirList
  echo "<li><a href='${wwwRootPath}/${satelliteDirectory}/img/$(date +"%Y/%m/%d")/index.html'>Today</a>" >> $dirList
  echo "<span class='badge badge-pill badge-light'>$howManyToday</span> </li>" >> $dirList

  for y in $(ls $satelliteDirectory/img/ | sort -n)
  do
    echo "<li>$y<ul>" >> $dirList
    for m in $(ls $satelliteDirectory/img/$y | sort -n)
    do
      echo "<li>($m)" >> $dirList
      for d in $(ls $satelliteDirectory/img/$y/$m/ | sort -n)
      do
        indexFile="${satelliteDirectory}/img/$y/$m/$d/index.html"
        # Only add a link to the index file if there is an index file.
        if [[ -f "${indexFile}" ]];
        then
          # collect info about files in the directory
          echo "<a href='${wwwRootPath}/${indexFile}'>$d</a> " >> $dirList
        fi
      done
      echo "</li>" >> $dirList
    done
    echo "</ul></li>" >> $dirList
  done
  echo "</ul>" >> $dirList
}

# ---- NOAA list all dates and times  -------------------------------------------------#

function gallery_noaa {
  local images lastRecFile
  lastRecFile="noaa-last-recording.tmp"
  images="<img src='$(cat $wwwDir/${lastRecFile})-therm+map.th.jpg' alt='recent recording' class='img-thumbnail' />"
  images="${images} <img src='$(cat $wwwDir/${lastRecFile})-MCIR-precip+map.th.jpg' alt='recent recording' class='img-thumbnail' />"
  images="${images} <img src='$(cat $wwwDir/${lastRecFile})-HVC+map.th.jpg' alt='recent recording' class='img-thumbnail' />"
  images="${images} <img src='$(cat $wwwDir/${lastRecFile})-NO+map.th.jpg' alt='recent recording' class='img-thumbnail' />"
  generateGallery --satDir=$noaaDir --title="NOAA Recordings" --lastRecFile="${lastRecFile}" --imagesHtml="${images}"
} # end function gallery noaa

# ---- METEOR list all dates and times  -------------------------------------------------#


function gallery_meteor {
  local images lastRecFile
  lastRecFile="meteor-last-recording.tmp"
  images="<img src='$(cat $wwwDir/${lastRecFile}).th.jpg' alt='recent recording' class='img-thumbnail' />"
  generateGallery --satDir=$meteorDir --title="METEOR-M2 Recordings" --lastRecFile="${lastRecFile}" --imagesHtml="${images}"
} # end function gallery meteor



# ---- ISS loop all dates and times  -------------------------------------------------#
function gallery_iss {

howManyToday=$(ls $recordingDir/iss/rec/$(date +"%Y/%m/")/*.log 2> /dev/null| wc -l)

echo "<h2>ISS recordings</h2>" >> $dirList
echo "<ul>" >> $dirList
echo "<li><a href='${wwwRootPath}/recordings/iss/rec/$(date +"%Y/%m/")'>Current month</a> <span class='badge badge-pill badge-light'>$howManyToday</span>" >> $dirList

for y in $(ls $recordingDir/iss/rec/ | sort -n)
do
  echo "<li>($y) " >> $dirList
  for m in $(ls $recordingDir/iss/rec/$y | sort -n)
  do
    echo "<a href='${wwwRootPath}/recordings/iss/rec/$y/$m/'>$m</a> " >> $dirList
  done
  echo "</li>" >> $dirList
done
echo "</ul>" >> $dirList

}

# ---- LOGS  -------------------------------------------------#

function gallery_logs {


  echo "<h2>Logs</h2>" >> $dirList
  echo "<ul>"  >> $dirList
  echo "<li><a href='${wwwRootPath}/recordings/logs/$(date +"%Y-%m-%d").txt'>Today</a></li>" >> $dirList
  echo "<li><a href='${wwwRootPath}/recordings/logs/'>All logs</a></li>" >> $dirList
  echo "</ul>"  >> $dirList
}

# ---- dump1090  -------------------------------------------------#

function gallery_dump1090 {
  echo "<h2>dump1090 heatmap</h2>" >> $dirList
  echo "<img src='${wwwRootPath}/recordings/dump1090/heatmap-osm.jpg' alt='dump1090 heatmap' class="img-thumbnail" />" >> $dirList
  echo "<img src='${wwwRootPath}/recordings/dump1090/heatmap-osm2.jpg' alt='dump1090 heatmap' class="img-thumbnail" />" >> $dirList
}


# ------------------------------------------template engine --------------------- #

# ----- RENDER APPROPRIATE PAGES ---- #

if [ "$includeGalleryNoaa" = '1' ]; then
  gallery_noaa
fi

if [ "$includeGalleryMeteor" = '1' ]; then
  gallery_meteor
fi

if [ "$includeGalleryLogs" = '1' ]; then
  gallery_logs
fi

if [ "$includeGalleryISS" = '1' ]; then
  gallery_iss
fi

if [ "$includeGalleryDump1090" = '1' ]; then
  gallery_dump1090
fi


# ----- MAIN PAGE ---- #

htmlTitle="Main page"
htmlBody=$(cat $dirList)
source $htmlTemplate > $htmlOutput

# ----- PASS LIST ---- #

htmlTitle="Pass table"
htmlBody=$(cat $htmlNextPassList)
htmlBody="<p><img src='nextpass.png' alt='pass table plot' /></p>"$htmlBody

source $htmlTemplate > $htmlOutputTable
