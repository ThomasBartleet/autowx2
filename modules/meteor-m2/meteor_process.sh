#!/bin/bash


processedFile="${recdir}/${3}"
imageFile="${imgdir}/${3}"
normalisedAudioFile="${processedFile}.wav"
demodulatedAudioFile="${processedFile}.qpsk"
decodedAudioFile="${processedFile}.dec"


# Demodulate the audio file
echo "Demodulation in progress (QPSK)"
meteor_demod -B -o $demodulatedAudioFile $normalisedAudioFile

# Decode th demoodulated file
echo "Decoding in progress (QPSK to BMP)"
./medet/medet_arm $demodulatedAudioFile $processedFile -cd

# Get the image file extension
if [ "$imageExtension" == "" ]; then
  imageExtension = "jpg"
fi

# Should we resize the image?
if [ "$resizeimageto" != "" ]; then
  echo "Resizing image to $resizeimageto px"
  resizeSwitch="-resize ${resizeimageto}x${resizeimageto}>"
fi

# Decide the file and make image.
if [ -f $decodedAudioFile ]; then
    echo "I got a successful ${3}.dec file. Creating false color image"
    ./medet/medet_arm $decodedAudioFile "${iageFile}-122" -r 66 -g 65 -b 64 -d
    convert $resizeSwitch "${imageFile}-122.bmp" "${imageFile}.${imageExtension}"
    rm "${imageFile}-122.bmp"
else
    echo "[DEBUG] Meteor Decoding failed, either a bad pass/low SNR or a software problem"
fi

if [ "${removeAudio}" -ne "" ]; then
    rm $normalisedAudioFile
    rm $demodulatedAudioFile
fi