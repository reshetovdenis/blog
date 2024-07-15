#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <input_video> <output_video> <text>"
  exit 1
fi

# Assign input arguments to variables
INPUT_VIDEO="$1"
OUTPUT_VIDEO="$2"
BASE_NAME="$3"

INTRO_LENGTH_SEC=0.5
FONT_SIZE=140
BORDER_WIDTH=8
CHAR_LIMIT=10
INDENT=75
UPLIFT=95
PADDING_LEFT=120
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

# Split the base name into words
IFS=' ' read -r -a WORDS <<< "$BASE_NAME"
PART1=""
PART2=""
PART3=""
PART4=""
CURRENT_PART=1
CURRENT_CHARS=0

# Define the limit of characters across all parts
for word in "${WORDS[@]}"; do
    WORD_LENGTH=${#word}
    case $CURRENT_PART in
        1)
            if [ $((CURRENT_CHARS + WORD_LENGTH)) -le $CHAR_LIMIT ]; then
                [ -n "$PART1" ] && PART1="$PART1 $word" || PART1="$word"
                CURRENT_CHARS=$((CURRENT_CHARS + WORD_LENGTH + 1))
            else
                CURRENT_PART=2
                CURRENT_CHARS=0
                PART2="$word"
                CURRENT_CHARS=$((WORD_LENGTH + 1))
            fi
            ;;
        2)
            if [ $((CURRENT_CHARS + WORD_LENGTH)) -le $CHAR_LIMIT ]; then
                [ -n "$PART2" ] && PART2="$PART2 $word" || PART2="$word"
                CURRENT_CHARS=$((CURRENT_CHARS + WORD_LENGTH + 1))
            else
                CURRENT_PART=3
                CURRENT_CHARS=0
                PART3="$word"
                CURRENT_CHARS=$((WORD_LENGTH + 1))
            fi
            ;;
        3)
            if [ $((CURRENT_CHARS + WORD_LENGTH)) -le $CHAR_LIMIT ]; then
                [ -n "$PART3" ] && PART3="$PART3 $word" || PART3="$word"
                CURRENT_CHARS=$((CURRENT_CHARS + WORD_LENGTH + 1))
            else
                CURRENT_PART=4
                CURRENT_CHARS=0
                PART4="$word"
                CURRENT_CHARS=$((WORD_LENGTH + 1))
            fi
            ;;
        4)
            if [ $((CURRENT_CHARS + WORD_LENGTH)) -le $CHAR_LIMIT ]; then
                [ -n "$PART4" ] && PART4="$PART4 $word" || PART4="$word"
                CURRENT_CHARS=$((CURRENT_CHARS + WORD_LENGTH + 1))
            fi
            ;;
    esac
done

# Convert arrays to strings and make uppercase
PART1=$(echo "$PART1" | tr '[:lower:]' '[:upper:]')
PART2=$(echo "$PART2" | tr '[:lower:]' '[:upper:]')
PART3=$(echo "$PART3" | tr '[:lower:]' '[:upper:]')
PART4=$(echo "$PART4" | tr '[:lower:]' '[:upper:]')

escape_single_quotes() {
    echo "$1" | sed "s/'/'\\\\\\\\\\\\''/g"
}

# Escape single quotes in the parts
PART1=$(escape_single_quotes "$PART1")
PART2=$(escape_single_quotes "$PART2")
PART3=$(escape_single_quotes "$PART3")
PART4=$(escape_single_quotes "$PART4")

ffmpeg -i "$INPUT_VIDEO" -filter_complex "
[0:v]
drawtext=fontfile='./roboto.ttf':text='$PART1':fontcolor=$FIRST_COLOR:bordercolor=$FIRST_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 - (3*$INDENT+$UPLIFT),
drawtext=fontfile='./roboto.ttf':text='$PART2':fontcolor=$SECOND_COLOR:bordercolor=$SECOND_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 - $INDENT-$UPLIFT,
drawtext=fontfile='./roboto.ttf':text='$PART3':fontcolor=$THIRD_COLOR:bordercolor=$THIRD_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 + $INDENT-$UPLIFT,
drawtext=fontfile='./roboto.ttf':text='$PART4':fontcolor=$FOURTH_COLOR:bordercolor=$FOURTH_OUTLINE:borderw=$BORDER_WIDTH:fontsize=$FONT_SIZE:x=$PADDING_LEFT:y=(h-text_h)/2 + (3*$INDENT-$UPLIFT)" -c:v libx264 -c:a aac -strict experimental "$OUTPUT_VIDEO"