#!/bin/bash

# Check if a file name was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <video_file>"
    exit 1
fi

# Assign the video file to a variable
VIDEO_FILE="$1"

# Extract the base name without extension to use as header text
BASE_NAME=$(basename "$VIDEO_FILE" .mp4)  # Adjust the extension as necessary

# Split the base name into words
IFS=' ' read -r -a WORDS <<< "$BASE_NAME"
NUM_WORDS=${#WORDS[@]}
HALF_INDEX=$((NUM_WORDS / 2))

# Join words into two parts
HALF1="${WORDS[@]:0:$HALF_INDEX}"
HALF2="${WORDS[@]:$HALF_INDEX}"

# Convert arrays to strings and make uppercase
HALF1=$(echo "${HALF1[@]}" | tr '[:lower:]' '[:upper:]')
HALF2=$(echo "${HALF2[@]}" | tr '[:lower:]' '[:upper:]')

# Extract the frame rate using ffprobe
FRAME_RATE=$(ffprobe -v error -select_streams v -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")
FPS=$(echo "scale=2; $FRAME_RATE" | bc)

# Generate the intro video with text overlay using the split and capitalized file name
ffmpeg -i "$VIDEO_FILE" -t 3 -filter_complex "
[0:v]fps=fps=$FPS,
drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$HALF1':fontcolor=#FBF4CC:bordercolor=#0375B8:borderw=5:fontsize=75:x=(w-text_w)/2:y=(h-text_h)/2 - 100,
drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$HALF2':fontcolor=#FBF4CC:bordercolor=#F59C04:borderw=5:fontsize=75:x=(w-text_w)/2:y=(h-text_h)/2 + 50" -c:v libx264 -c:a aac -strict experimental intro.mp4

# Extract the rest of the video
ffmpeg -ss 3 -i "$VIDEO_FILE" -c:v libx264 -c:a aac main.mp4

# Concatenate the videos using the concat demuxer
echo "file 'intro.mp4'" > filelist.txt
echo "file 'main.mp4'" >> filelist.txt
ffmpeg -f concat -safe 0 -i filelist.txt -c:v libx264 -c:a aac output.mp4

# Remove intermediate files
rm intro.mp4 main.mp4 filelist.txt

echo "Process completed. The output file is output.mp4."

