#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 input_video overlay_image output_video position"
  echo "Position options: topleft, topright, bottomleft, bottomright"
  exit 1
fi

# Assign input arguments to variables
INPUT_VIDEO="$1"
OVERLAY_IMAGE="$2"
OUTPUT_VIDEO="$3"
POSITION="$4"

# Determine overlay position
case "$POSITION" in
  topleft)
    OVERLAY_POSITION="10:10"
    ;;
  topright)
    OVERLAY_POSITION="main_w-overlay_w-10:10"
    ;;
  bottomleft)
    OVERLAY_POSITION="10:main_h-overlay_h-10"
    ;;
  bottomright)
    OVERLAY_POSITION="main_w-overlay_w-10:main_h-overlay_h-10"
    ;;
  *)
    echo "Invalid position option. Use: topleft, topright, bottomleft, bottomright."
    exit 1
    ;;
esac

# Execute the ffmpeg command to overlay the image
ffmpeg -i "$INPUT_VIDEO" -i "$OVERLAY_IMAGE" -filter_complex "overlay=$OVERLAY_POSITION" -codec:a copy "$OUTPUT_VIDEO"

# Check if ffmpeg command was successful
if [ $? -eq 0 ]; then
  echo "Overlay image successfully added to the video."
else
  echo "Failed to overlay image on the video."
fi