#!/bin/bash

source $baseDir/shell_functions.sh

processedFile="${recdir}/${1}"
imageFile="${imgdir}/${1}"
normalisedAudioFile="${processedFile}.wav"
demodulatedAudioFile="${processedFile}.qpsk"
decodedAudioFile="${processedFile}.dec"

make_image() {
  decodingType="${1}"
  echo "**** ${decodingType}"
  outputConversionImage="${imageFile}-125"
  outputImage="${imageFile}.${imageExtension}"
  if [ "${decodingType}" == "RGB" ]; then
    debugEcho "Decoding colour image"
    ./medet/medet_arm $decodedAudioFile "${outputConversionImage}" -r 66 -g 65 -b 64 -d
  elif [ "${decodingType}" == "IR" ]; then
    debugEcho "Decoding IR image"
    ./medet/medet_arm $decodedAudioFile "${outputConversionImage}" -r 68 -g 68 -b 68 -d
  fi

  convert $resizeSwitch "${outputConversionImage}.bmp" "${outputImage}"
  if [ -f "${outputImage}" ]; then
    rm "${outputConversionImage}.bmp"
  fi
}


# Demodulate the audio file
debugEcho "Demodulation in progress (QPSK)"
meteor_demod -B -o $demodulatedAudioFile $normalisedAudioFile

# Decode th demoodulated file
debugEcho "Decoding in progress (QPSK to BMP)"
./medet/medet_arm $demodulatedAudioFile $processedFile -cd

# Get the image file extension
if [ "$imageExtension" == "" ]; then
  imageExtension="jpg"
fi

# Should we resize the image?
if [ "$resizeimageto" != "" ]; then
  debugEcho "Resizing image to $resizeimageto px"
  resizeSwitch="-resize ${resizeimageto}x${resizeimageto}>"
fi

# Decide the file and make image.
if [ -f $decodedAudioFile ]; then
    debugEcho "I got a successful .dec file. Creating false color image"

    make_image "RGB"
else
    debugEcho "Meteor Decoding failed, either a bad pass/low SNR or a software problem"
fi

if [ "${removeFiles}" -ne "" ]; then
    rm $normalisedAudioFile
    rm $demodulatedAudioFile
fi

# Remove old data
removeOldData -t $keepDataForDays -d $rootMeteorImgDir
removeOldData -t $keepDataForDays -d $rootMeteorRecDir