#!/bin/bash

debugEcho() {
  echo "[DEBUG] $1"
}


function removeFolderFromDirectory() {
  # This function must have two parameters:
  #   $1 - the folder name to remove
  #   $2 - the directory from which to remove $1 from
  #   $3 - [OPTIONAL] Show messages
  if [ $# -lt 2 ]; then
    echo "Illegal number of parameters"
    return -1
  fi

  showEcho=""

  while getopts "s" arg; do
    case $arg in
      s) showEcho="true";;
    esac
  done

  if [ $showEcho ]; then
    currentDir=$(pwd)
    debugEcho "From current directory: ${currentDir}"
    debugEcho "Trying to remove ${1} from ${2}"
  fi

  # Check that the full path is valid
  if [ ! -d $2/$1/ ]; then
    if [ $showEcho ]; then
      echo "Full path not found: $2/$1/"
    fi
    return -1
  fi

  # Path has been found, therefore remove it.
  rm -drf $2/$1/

  return 0
}

removeOldData() {
  # https://stackoverflow.com/a/16655341
  local OPTIND directory timeDays arg
  while getopts ":d:t:" arg; do
    case $arg in
      d) 
        directory="${OPTARG}"
        ;;

      t) 
        timeDays=$OPTARG
        # Check if $timeDays is not a whole number:
        re_isanum='^[0-9]+$' # Regex: match whole positive numbers only
        if ! [[ $timeDays =~ $re_isanum ]] ; 
        then
          echo "Error - Invalid timeDays: ${timeDays}"
          echo "Error - timeDays must be a positive, whole number."
          return -1
        fi
        ;;
    esac
  done
  shift $((OPTIND-1))

  if [[ ! $directory || ! -d $directory ]];
  then
    echo "Error - Invalid directory: ${directory}"
    return -1
  fi

  # Remove old data
  if [ $timeDays -gt 0 ]; then
    debugEcho "Checking for old removable data from over ${timeDays} days ago."
    # Check the dates
    oldDateUnix=$(date --date="$timeDays days ago" +%s)

    oldYear=$(date --date="@$oldDateUnix" +%Y)
    oldMonth=$(date --date="@$oldDateUnix" +%m)
    oldDay=$(date --date="@$oldDateUnix" +%d)

    newYear=$(date +%Y)
    newMonth=$(date +%m)
    newDay=$(date +%d)
    
    debugEcho "Old year: ${oldYear}  New year: ${newYear}"
    debugEcho "Old month: ${oldMonth}  New month: ${newMonth}"
    debugEcho "Old day: ${oldDay}  New day: ${newDay}"

    # Remove data
    monthCounter=1
    while [ $monthCounter -lt $oldMonth ]
    do
      monthCounterAsString=$(printf "%02d" $monthCounter)
      dayCounter=1
      while [ $dayCounter -lt $oldDay ]
      do
        dayCounterAsString=$(printf "%02d" $dayCounter)
        removeFolderFromDirectory $dayCounterAsString $directory/$oldYear/$oldMonth
        (( dayCounter++ ))
      done
      removeFolderFromDirectory $monthCounterAsString $directory/$oldYear
      (( monthCounter++ ))
    done

    if [ $oldYear -lt $newYear ]; then
      # The old year is different than the new year (ie old year is the previous year). Therefore,
      # just remove the entire directory.
      removeFolderFromDirectory $oldYear $directory
    fi
  else
    debugEcho "[timeDays] set to ${timeDays}. Removing nothing."
  fi
}