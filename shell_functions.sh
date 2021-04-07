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

  if [ $timeDays -le 0 ]; then
    debugEcho "[timeDays] set to ${timeDays}. Removing nothing."
    return 0
  fi

  # Remove old data, when timeDays > 0
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

  # Start data removal process.

  # Start the year counter at 2020, as this is the year this feature was
  # first implemented.
  for (( yearCounter=2020; yearCounter <= $newYear; yearCounter++ )) 
  # for yearCounter in {2020..$newYear}
  do
    # Check the directory exists. If it does not, move on.
    if [ ! -d "${directory}/${yearCounter}" ]; then
      continue
    fi

    debugEcho "Checking directory: ${directory}/${yearCounter}"

    # We've established that the directory for the year exists. We now need to
    # check whether the month directories exist.
    for monthCounter in {1..12} # Highest month is 12 (Dec).
    do
      monthCounterAsString=$(printf "%02d" $monthCounter)

      # Check the month directory exists. If it does not, move on.
      if [ ! -d "${directory}/${yearCounter}/${monthCounterAsString}" ]; then
        continue
      fi

      debugEcho "Checking directory: ${directory}/${yearCounter}/${monthCounterAsString}"

      for dayCounter in {1..31} # Highest number of days in a month is 31
      do
        dayCounterAsString=$(printf "%02d" $dayCounter)

        # Check the month directory exists. If it does not, move on.
        if [ ! -d "${directory}/${yearCounter}/${monthCounterAsString}/${dayCounterAsString}" ]; then
          continue
        fi

        debugEcho "Checking directory: ${directory}/${yearCounter}/${monthCounterAsString}/${dayCounterAsString}"

        # Get the date from the year, month, and day counters as a unix
        # timestamp. We will set the threashold at midnight.
        directoryDateUnix=$(date -d "${yearCounter}-${monthCounterAsString}-${dayCounterAsString}T00:00:00+00:00" +%s)

        [ $directoryDateUnix -le $oldDateUnix ] && echo "Directory ${directory}/${yearCounter}/${monthCounterAsString}/${dayCounterAsString} should be removed"

        # Compare with the oldest date the data should be. If the old date is
        # greater than the directory date, the directory should be removed.
        if [ $directoryDateUnix -le $oldDateUnix ]; then
          removeFolderFromDirectory $dayCounterAsString $directory/$oldYear/$oldMonth
        fi
      done

      # If there are no files/folders in the month's directory, there's no
      # point in keeping it.
      if [ -z "$(ls -A "${directory}/${yearCounter}/${monthCounterAsString}" 2>/dev/null)" ]; then
        removeFolderFromDirectory $monthCounterAsString $directory/$yearCounter
      fi
    done
  done

  # If there are no files/folders in the month's directory, there's no
  # point in keeping it.
  if [ -z "$(ls -A "${directory}/${yearCounter}" 2>/dev/null)" ]; then
    removeFolderFromDirectory $yearCounter $directory
  fi
}