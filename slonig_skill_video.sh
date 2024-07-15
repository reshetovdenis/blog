#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <URL> <HEADER>"
    exit 1
fi

URL=$1
HEADER=$2
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="/Users/adr/tmp/slonig_${TIMESTAMP}.MP4"

# Run the screenshot.py script with the provided URL
./screenshot.py "$URL"

# Check if screenshot.py ran successfully
if [ $? -ne 0 ]; then
    echo "screenshot.py failed"
    exit 1
fi

# Array of folders to be used as parameter for generate_reel.sh
FOLDERS=(
    "/Users/adr/localGoogleDrive/Instagram/reels/eng/slonig/location_recoded/2/"
    "/Users/adr/localGoogleDrive/Instagram/reels/eng/slonig/location_recoded/3/"
)

# Check if the folders array is empty
if [ ${#FOLDERS[@]} -eq 0 ]; then
    echo "Error: Folders array is empty."
    exit 1
fi

# Temporary cache file to store the last used folder index
CACHE_FILE="./last_used_folder_index.txt"

# Read the last used folder index from the cache file
if [ -f "$CACHE_FILE" ]; then
    LAST_USED_INDEX=$(cat "$CACHE_FILE")
else
    LAST_USED_INDEX=-1
fi

# Determine the next folder index
if [ "$LAST_USED_INDEX" -ge $((${#FOLDERS[@]} - 1)) ]; then
    NEXT_INDEX=0
else
    NEXT_INDEX=$((LAST_USED_INDEX + 1))
fi

# Store the next index in the cache file
echo "$NEXT_INDEX" > "$CACHE_FILE"

# Get the next folder path
NEXT_FOLDER=${FOLDERS[$NEXT_INDEX]}

./generate_reel.sh "$NEXT_FOLDER" "$OUTPUT_FILE" "$HEADER"

# Check if generate_reel.sh ran successfully
if [ $? -ne 0 ]; then
    echo "generate_reel.sh failed"
    exit 1
fi

echo "Process completed successfully. Output file: $OUTPUT_FILE"