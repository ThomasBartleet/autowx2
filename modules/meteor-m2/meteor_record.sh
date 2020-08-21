#!/bin/bash

### WARNING: all dates and times must be in the UTC!

startT=$(date +%H%M -d "$DATE + 1 min" -u)
stopT=$(date +%H%M -d "$DATE + $duration sec" -u)
durationMin=$(bc <<< "$duration/60 +2")

#
# recording
#
echo "$startT-$stopT, duration: $durationMin min"
# mlrpt -s $startT-$stopT -t $durationMin -c M2-1-SA7BNT.cfg

# return 0

# I don't have an LNA or similar between my SDR and my antenna, so
# I don't need the below.
# BIAS_TEE="enable_bias_tee"

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Satellite max elevation

echo "Satellite Name=$1"
echo "Frequency=$2"
echo "FileName base=$3"
echo "TLE File=$4"
echo "EPOC start time=$5"
echo "Time to capture=$6"
echo "Satellite max elevation=$7"

rawDirectory="${recdir}/raw"
rawAudioFile="${rawDirectory}/${3}.wav"
processedFile="${recdir}/${3}"
normalisedAudioFile="${processedFile}.wav"
demodulatedAudioFile="${processedFile}.qpsk"
decodedAudioFile="${processedFile}.dec"

# Create folders if they don't exist
mkdir -p $rawDirectory

echo "Starting rtl_fm record"
timeout ${6} rtl_fm -f ${2} -M raw -s 288k -g 48 -p 1 | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav $rawAudioFile rate 96k

echo "Normalization in progress"
sox $rawAudioFile $normalisedAudioFile gain -n


echo "Demodulation in progress (QPSK)"
meteor_demod -B -o $demodulatedAudioFile $normalisedAudioFile

# if [ "$DELETE_AUDIO" = true ]; then
#     rm "${recdir}/raw/${3}.wav"
#     rm "${recdir}/${3}.wav"
# fi

echo "Decoding in progress (QPSK to BMP)"
./medet/medet_arm $demodulatedAudioFile $processedFile -cd

# rm "${recdir}/${3}.qpsk"

if [ -f $decodedAudioFile ]; then
    echo "I got a successful ${3}.dec file. Creating false color image"
    ./medet/medet_arm $decodedAudioFile "${imgdir}/${3}-122" -r 66 -g 65 -b 64 -d
    # convert "${imgdir}/${3}-122.bmp" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.jpg"
    # echo "Rectifying image to adjust aspect ratio"
    # python3 "${NOAA_HOME}/rectify.py" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.jpg"
    # rm "${imgdir}/${3}-122.bmp"
    # rm "${imgdir}/${3}.bmp"
else
    echo "[DEBUG] Meteor Decoding failed, either a bad pass/low SNR or a software problem"
fi
