#!/bin/bash

# Check if the correct number of arguments were provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <new_directory> <with_covers_directory> <no_covers_directory>"
    exit 1
fi

INTRO_LENGTH_SEC=0.5
FONT_SIZE=140
BORDER_WIDTH=8
CHAR_LIMIT=9
INDENT=75
UPLIFT=95
PADDING_LEFT=120
INPUT_DIR="$1"
OUTPUT_DIR="$2"
STORAGE_DIR="$3"
TIMESTAMP=$(date +%s%3)

# Define color values
BLUE="#FBF4CC"
BLUE_OUTLINE="#0375B8"
ORANGE="#FBF4CC"
ORANGE_OUTLINE="#F59C04"

# Create arrays for color and outline pairs
colors=("$BLUE" "$ORANGE")
outlines=("$BLUE_OUTLINE" "$ORANGE_OUTLINE")

# Function to assign colors randomly to variables
assign_colors() {
    local index=$(shuf -i 0-1 -n 1)  # Generate a random index 0 or 1
    echo "${colors[$index]}" "${outlines[$index]}"
}

# Assign colors and outlines to each line independently
read FIRST_COLOR FIRST_OUTLINE <<< $(assign_colors)
read SECOND_COLOR SECOND_OUTLINE <<< $(assign_colors)
read THIRD_COLOR THIRD_OUTLINE <<< $(assign_colors)
read FOURTH_COLOR FOURTH_OUTLINE <<< $(assign_colors)

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist."
    exit 1
fi

# Check if with_covers directory exists
if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: With covers directory '$OUTPUT_DIR' does not exist."
    exit 1
fi

# Check if no_covers directory exists
if [ ! -d "$STORAGE_DIR" ]; then
    echo "Error: With covers directory '$STORAGE_DIR' does not exist."
    exit 1
fi

# Iterate over all mp4 files in the input directory
for VIDEO_FILE in "$INPUT_DIR"/*.MP4; do
    # Extract the base name without extension to use as header text
    BASE_NAME=$(basename "$VIDEO_FILE" .MP4)  # Adjust the extension as necessary

    # Split the base name into words
    IFS=' ' read -r -a WORDS <<< "$BASE_NAME"
    TOTAL_CHARS=0
    PART1=""
    PART2=""
    PART3=""
    PART4=""

    # Define the limit of characters across all parts
    

    for word in "${WORDS[@]}"; do
        # Calculate the length of the current word plus a space (if it's not the first word in the part)
        WORD_LENGTH=${#word}
        [ -n "$PART1" ] && WORD_LENGTH=$((WORD_LENGTH + 1))
        
        # Assign words to parts until the character limit is reached
        if [ $((TOTAL_CHARS + WORD_LENGTH)) -le $CHAR_LIMIT ]; then
            if [ -n "$PART1" ]; then
                PART1="$PART1 $word"
            else
                PART1="$word"
            fi
            TOTAL_CHARS=$((TOTAL_CHARS + WORD_LENGTH))
        elif [ $((TOTAL_CHARS + WORD_LENGTH)) -le $((2 * CHAR_LIMIT)) ]; then
            if [ -n "$PART2" ]; then
                PART2="$PART2 $word"
            else
                PART2="$word"
            fi
            TOTAL_CHARS=$((TOTAL_CHARS + WORD_LENGTH))
        elif [ $((TOTAL_CHARS + WORD_LENGTH)) -le $((3 * CHAR_LIMIT)) ]; then
            if [ -n "$PART3" ]; then
                PART3="$PART3 $word"
            else
                PART3="$word"
            fi
            TOTAL_CHARS=$((TOTAL_CHARS + WORD_LENGTH))
        elif [ $((TOTAL_CHARS + WORD_LENGTH)) -le $((4 * CHAR_LIMIT)) ]; then
            if [ -n "$PART4" ]; then
                PART4="$PART4 $word"
            else
                PART4="$word"
            fi
            TOTAL_CHARS=$((TOTAL_CHARS + WORD_LENGTH))
        else
            break  # Stop adding words if the limit for all parts is reached
        fi
    done


    # Convert arrays to strings and make uppercase
    PART1=$(echo "${PART1[@]}" | tr '[:lower:]' '[:upper:]')
    PART2=$(echo "${PART2[@]}" | tr '[:lower:]' '[:upper:]')
    PART3=$(echo "${PART3[@]}" | tr '[:lower:]' '[:upper:]')
    PART4=$(echo "${PART4[@]}" | tr '[:lower:]' '[:upper:]')

    escape_single_quotes() {
        echo "$1" | sed "s/'/'\\\\\\\\\\\\''/g"
    }

    # Example usage
    PART1=$(escape_single_quotes "$PART1")
    PART2=$(escape_single_quotes "$PART2")
    PART3=$(escape_single_quotes "$PART3")
    PART4=$(escape_single_quotes "$PART4")

    # Extract the frame rate using ffprobe
    FRAME_RATE=$(ffprobe -v error -select_streams v -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")
    FPS=$(echo "scale=2; $FRAME_RATE" | bc)

    # Ensure correct video speed by using -filter:v "fps=$FPS" in ffmpeg commands
    ffmpeg -i "$VIDEO_FILE" -t $INTRO_LENGTH_SEC -filter_complex "
    [0:v]fps=fps=$FPS,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART1':fontcolor=$FIRST_COLOR:bordercolor=$FIRST_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 - (3*$INDENT+$UPLIFT),
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART2':fontcolor=$SECOND_COLOR:bordercolor=$SECOND_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 - $INDENT-$UPLIFT,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART3':fontcolor=$THIRD_COLOR:bordercolor=$THIRD_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 + $INDENT-$UPLIFT,
    drawtext=fontfile='/System/Library/Fonts/Supplemental/Futura.ttc':text='$PART4':fontcolor=$FOURTH_COLOR:bordercolor=$FOURTH_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 + (3*$INDENT-$UPLIFT)" -c:v libx264 -c:a aac -strict experimental "$OUTPUT_DIR/${TIMESTAMP}-intro.MP4"

    # Extract the rest of the video at correct speed
    ffmpeg -ss $INTRO_LENGTH_SEC -i "$VIDEO_FILE" -filter:v "fps=fps=$FPS" -c:v libx264 -c:a aac "$OUTPUT_DIR/${TIMESTAMP}-main.MP4"

    # Concatenate the videos using the concat demuxer
    echo "file '${TIMESTAMP}-intro.MP4'" > "$OUTPUT_DIR/filelist.txt"
    echo "file '${TIMESTAMP}-main.MP4'" >> "$OUTPUT_DIR/filelist.txt"
    ffmpeg -y -f concat -safe 0 -i "$OUTPUT_DIR/filelist.txt" -c:v libx264 -c:a aac "$OUTPUT_DIR/${BASE_NAME}.MP4"

    # Remove intermediate files
    rm "$OUTPUT_DIR/${TIMESTAMP}-intro.MP4" "$OUTPUT_DIR/${TIMESTAMP}-main.MP4" "$OUTPUT_DIR/filelist.txt"
    # Move initial file to storage
    mv "$VIDEO_FILE" $STORAGE_DIR
done