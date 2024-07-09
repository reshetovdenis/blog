#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

URL=$1
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="/Users/adr/tmp/slonig_${TIMESTAMP}.MP4"

# Run the screenshot.py script with the provided URL
./screenshot.py "$URL"

# Check if screenshot.py ran successfully
if [ $? -ne 0 ]; then
    echo "screenshot.py failed"
    exit 1
fi

# Run the generate_reel.sh script with the temporary directory and the output file
./generate_reel.sh ~/localGoogleDrive/Instagram/reels/eng/slonig/location_recoded/3_short/ "$OUTPUT_FILE"

# Check if generate_reel.sh ran successfully
if [ $? -ne 0 ]; then
    echo "generate_reel.sh failed"
    exit 1
fi

echo "Process completed successfully. Output file: $OUTPUT_FILE"