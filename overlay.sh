#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 input_video overlay_image output_video"
  exit 1
fi

# Assign input arguments to variables
INPUT_VIDEO="$1"
OVERLAY_IMAGE="$2"
OUTPUT_VIDEO="$3"

# Calculate the overlay position
OVERLAY_POSITION="(main_w-overlay_w)/2:(main_h*0.25)"

# Execute the ffmpeg command to overlay the image
ffmpeg -i "$INPUT_VIDEO" -i "$OVERLAY_IMAGE" -filter_complex "overlay=$OVERLAY_POSITION" -codec:a copy "$OUTPUT_VIDEO"

# Check if ffmpeg command was successful
if [ $? -eq 0 ]; then
  echo "Overlay image successfully added to the video."
else
  echo "Failed to overlay image on the video."
fi
