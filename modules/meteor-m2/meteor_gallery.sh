#!/bin/bash

#
# moving recorded images to the appropriate final dir
#

# value for some tests:
# fileNameCore="20190118-1012_METEOR-M2"
# rawImageDir="./"



outHtml="$imgdir/$fileNameCore.html"  # html for this single pass
indexHtml="$imgdir/index.html"        # main index file for a given day
htmlTemplate="$wwwDir/index.tpl"


# ---single gallery preparation------------------------------------------------#

makethumb() {
    picture="$1"
    # Thumbnail can be in JPG, as we're not interested in super high quality for
    # the thumbnail image. The actual image is more important.
    local thumbnail=$(basename "$picture" .$imageExtension)".th.jpg"
    convert -define jpeg:size=200x200 "$picture" -thumbnail '200x200^' granite: +swap -gravity center -extent 200x200 -composite -quality 82 "$thumbnail"
    echo "$thumbnail"
    }

# -----------------------------------------------------------------------------#

logFile="$imgdir/$fileNameCore.log"   # log file to read from

varDate=$(sed '1q;d' $logFile)
varSat=$(sed '3q;d' $logFile)
varStart=$(sed '4q;d' $logFile) # unused
varDur=$(sed '5q;d' $logFile)
varPeak=$(sed '6q;d' $logFile)
varFreq=$(sed '7q;d' $logFile)

dateTime=$(date -d @$varStart +"%Y-%m-%d")
dateTimeDir=$(date -d @$varStart +"%Y/%m/%d")  # directory format of date, eg. 2018/11/22/
wwwPath="/recordings/meteor/img/${dateTimeDir}"




# -----------------------------------------------------------------------------#



cd "./var/www${wwwPath}"

if [ $(ls *.$imageExtension 2> /dev/null | wc -l) = 0 ];
then
  echo "No images found to add to gallery";
else

  #
  # some headers
  #

  echo "<h2>$varSat | $varDate</h2>" > $outHtml
  echo "<p>f=${varFreq}Hz, peak: ${varPeak}°, duration: ${varDur}s</p>" >> $outHtml

  #
  # loop over images and generate thumbnails
  #
  for image in *.$imageExtension
  do
    # Create thumbnail image if it doesn't already exist
    base=$(basename $image .$imageExtension | cut -d "." -f 1)
    if [ ! -f "${base}.th.jpg" ];
    then
  		echo "Thumb for $image"
      sizeof=$(du -sh "$image" | cut -f 1)
      # generate thumbnail
      thumbnail=$(makethumb "$image")
  		echo $thumbnail

      # If the base name is the same as the core filename, then we can add it.
      # Otherwise, we'd be adding a thumbnail that isn't part of this recording.
      if [ $base == $fileNameCore ];
      then
        echo "<a data-fancybox='gallery' data-caption='$varSat | $varDate ($sizeof)' href='$wwwPath/$image'><img src='$wwwPath/$thumbnail' alt='meteor image' title='$sizeof' class='img-thumbnail' /></a> " >> $outHtml
      fi
    fi
  done


  #
  # get image core name
  #
  # From the list of files, get the first file. From the file name, split that
  # string on the period character ('.'), and retain the 1st item (remove all
  # extensions).
  meteorcorename=$(ls *.$imageExtension | head -1 | cut -d "." -f 1)
  echo $wwwPath/$fileNameCore > $wwwDir/meteor-last-recording.tmp


  # ----consolidate data from the given day ------------------------------------#
  # generates neither headers nor footer of the html file

  echo "" > $indexHtml.tmp
  for htmlfile in $(ls $imgdir/*.html | grep -v "index.html")
  do
    cat $htmlfile >> $indexHtml.tmp
  done

  # ---------- generates pages according to the template file -------------------

  currentDate=$(date)
  echo $currentDate

  htmlTitle="METEOR-M2 images | $dateTime"
  htmlBody=$(cat $indexHtml.tmp)

  source $htmlTemplate > $indexHtml
fi # there are images
