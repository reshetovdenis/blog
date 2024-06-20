#!/bin/bash

# Check if the correct number of arguments were provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist."
    exit 1
fi

# Check if output directory exists, if not try to create it
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Could not create output directory '$OUTPUT_DIR'."
        exit 1
    fi
fi

# Iterate over all mp4 files in the input directory
for VIDEO_FILE in "$INPUT_DIR"/*.mp4; do
    # Extract the base name without extension to use as header text
    BASE_NAME=$(basename "$VIDEO_FILE" .mp4)  # Adjust the extension as necessary

    # Split the base name into words
    IFS=' ' read -r -a WORDS <<< "$BASE_NAME"
    NUM_WORDS=${#WORDS[@]}
    QUARTER_INDEX=$((NUM_WORDS / 4))

    # Join words into four parts
    PART1="${WORDS[@]:0:$QUARTER_INDEX}"
    PART2="${WORDS[@]:$QUARTER_INDEX:$QUARTER_INDEX}"
    PART3="${WORDS[@]:$((2 * QUARTER_INDEX)):$QUARTER_INDEX}"
    PART4="${WORDS[@]:$((3 * QUARTER_INDEX))}"

    # Convert arrays to strings and make uppercase
    PART1=$(echo "${PART1[@]}" | tr '[:lower:]' '[:upper:]')
    PART2=$(echo "${PART2[@]}" | tr '[:lower:]' '[:upper:]')
    PART3=$(echo "${PART3[@]}" | tr '[:lower:]' '[:upper:]')
    PART4=$(echo "${PART4[@]}" | tr '[:lower:]' '[:upper:]')

    # Extract the frame rate using ffprobe
    FRAME_RATE=$(ffprobe -v error -select_streams v -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")
    FPS=$(echo "scale=2; $FRAME_RATE" | bc)

    # Generate the intro video with text overlay using the split and capitalized file name
    ffmpeg -i "$VIDEO_FILE" -t 3 -filter_complex "
    [0:v]fps=fps=$FPS,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART1':fontcolor=#FBF4CC:bordercolor=#0375B8:borderw=5:fontsize=90:x=100:y=(h-text_h)/2 - 150,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART2':fontcolor=#FBF4CC:bordercolor=#F59C04:borderw=5:fontsize=90:x=100:y=(h-text_h)/2 - 50,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART3':fontcolor=#FBF4CC:bordercolor=#0375B8:borderw=5:fontsize=90:x=100:y=(h-text_h)/2 + 50,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART4':fontcolor=#FBF4CC:bordercolor=#F59C04:borderw=5:fontsize=90:x=100:y=(h-text_h)/2 + 150" -c:v libx264 -c:a aac -strict experimental "$OUTPUT_DIR/${BASE_NAME}-intro.mp4"

    # Extract the rest of the video
    ffmpeg -ss 3 -i "$VIDEO_FILE" -c:v libx264 -c:a aac "$OUTPUT_DIR/${BASE_NAME}-main.mp4"

    # Concatenate the videos using the concat demuxer
    echo "file '${BASE_NAME}-intro.mp4'" > "$OUTPUT_DIR/filelist.txt"
    echo "file '${BASE_NAME}-main.mp4'" >> "$OUTPUT_DIR/filelist.txt"
    ffmpeg -y -f concat -safe 0 -i "$OUTPUT_DIR/filelist.txt" -c:v libx264 -c:a aac "$OUTPUT_DIR/${BASE_NAME}.mp4"

    # Remove intermediate files
    rm "$OUTPUT_DIR/${BASE_NAME}-intro.mp4" "$OUTPUT_DIR/${BASE_NAME}-main.mp4" "$OUTPUT_DIR/filelist.txt"
done