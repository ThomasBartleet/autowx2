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
  		echo "Thumb for $image"
  		base=$(basename $image .$imageExtension)
      sizeof=$(du -sh "$image" | cut -f 1)
      # generate thumbnail
      thumbnail=$(makethumb "$image")
  		echo $thumbnail
      echo "<a data-fancybox='gallery' data-caption='$varSat | $varDate ($sizeof)' href='$wwwPath/$image'><img src='$wwwPath/$thumbnail' alt='meteor image' title='$sizeof' class='img-thumbnail' /></a> " >> $outHtml
  done


  #
  # get image core name
  #
  # From the full file name, get the head (?). From the file name:
  # 1. Split the string on the underscore character ('_'), and retain the 2nd item.
  # 2. Split that string on the period character ('.'), and retain the 1st item.
  meteorcorename=$(ls *.$imageExtension | head -1 | cut -d "_" -f 2 | cut -d "." -f 1)
  echo $wwwPath/$meteorcorename > $wwwDir/meteor-last-recording.tmp


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
