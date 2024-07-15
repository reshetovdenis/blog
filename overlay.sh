#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 input_video overlay_image output_video"
  exit 1
fi

# Assign input arguments to variables
INPUT_VIDEO="$1"
OVERLAY_IMAGE="$2"
OUTPUT_VIDEO="$3"
SHIFT_LEFT="$4"

# Get the overlay image dimensions
OVERLAY_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OVERLAY_IMAGE")
OVERLAY_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OVERLAY_IMAGE")

# Check if the overlay image height is greater than its width
if [ "$OVERLAY_HEIGHT" -gt "$OVERLAY_WIDTH" ]; then
  # Adjust the overlay image dimensions so that height equals width
  OVERLAY_FILTER="scale=iw*1.5:ih*1.5"
  # Calculate the overlay position so that the bottom of the overlay is at 63% of the video height
  OVERLAY_POSITION="(main_w-overlay_w)/2:(main_h*0.63-overlay_h)"
else
  # Scale the overlay image by 2.5 times its original dimensions
  OVERLAY_FILTER="scale=iw*2:ih*2"
  # Calculate the overlay position so that the bottom of the overlay is at 63% of the video height
  OVERLAY_POSITION="(main_w-overlay_w)/2-$SHIFT_LEFT:(main_h*0.63-overlay_h)"
fi



# Execute the ffmpeg command to scale the overlay image and add it to the video
ffmpeg -loglevel quiet -i "$INPUT_VIDEO" -i "$OVERLAY_IMAGE" -filter_complex "[1:v]$OVERLAY_FILTER[overlay];[0:v][overlay]overlay=$OVERLAY_POSITION" -codec:a copy "$OUTPUT_VIDEO"

# Check if ffmpeg command was successful
if [ $? -eq 0 ]; then
  echo "Overlay image successfully added to the video."
else
  echo "Failed to overlay image on the video."
fi