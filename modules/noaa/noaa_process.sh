#!/bin/bash

# file to process NOAA wav file to produce weather images
# all variables are provided by noaa.sh

#
# get the image file extension
#

if [ ! $imageExtension ]; then
  imageExtension="jpg"
fi

#
# generate map - only if configured to do so
#
if [ $mapOutline != 0 ]; then
  wxmap -T "$satellite" -a -H $tleFileName -o -O $duration -L "$latlonalt" $start $imgdir/$fileNameCore-mapa.png | tee -a $logFile
  withMapOutline="-m ${imgdir}/${fileNameCore}-mapa.png"
  withMapExtension="+map"
fi

#
# should we resize images?
#

if [ "$resizeimageto" != "" ]; then
  echo "Resizing images to $resizeimageto px"
  resizeSwitch="-resize ${resizeimageto}x${resizeimageto}>"
fi

#
# process wav file with various enchancements
#

for enchancement in "${enchancements[@]}"
do
  echo "**** $enhancement"
  wxtoimg -e $enchancement $withMapOutline $recdir/$fileNameCore.wav $imgdir/$fileNameCore-${enchancement}${withMapExtension}.png | tee -a $logFile
  convert -quality 91 $resizeSwitch $imgdir/$fileNameCore-${enchancement}${withMapExtension}.png $imgdir/$fileNameCore-${enchancement}${withMapExtension}.${imageExtension}
  if [ "$imageExtension" != "png" ]; then
      rm $imdir/$fileNameCore-${endhancement}${withMapExtension}.png
  fi
done

sox $recdir/$fileNameCore.wav -n spectrogram -o $imgdir/$fileNameCore-spectrogram.png
convert -quality 90 $imgdir/$fileNameCore-spectrogram.png $imgdir/$fileNameCore-spectrogram.jpg

rm $imgdir/$fileNameCore-mapa.png
rm $imgdir/$fileNameCore-spectrogram.png
rm $recdir/$fileNameCore.wav

# Remove old data
removeOldData -t $keepDataForDays -d $rootImgDir
removeOldData -t $keepDataForDays -d $rootRecDir