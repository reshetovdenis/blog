#!/bin/bash

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg could not be found, please install it."
    exit 1
fi

# Check if two parameters are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory_to_scan> <output_csv_file>"
    exit 1
fi

# Get parameters
scan_dir="$1"
output_file="$2"

# Check if the directory exists
if [ ! -d "$scan_dir" ]; then
    echo "Directory does not exist: $scan_dir"
    exit 1
fi

# Write CSV header
echo "Subdirectory,File Name,Length (seconds)" > "$output_file"

# Function to get video length
get_video_length() {
    local file="$1"
    ffmpeg -i "$file" 2>&1 | grep "Duration" | awk '{print $2}' | tr -d , | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}'
}

# Export function for subshells
export -f get_video_length

# Find all video files and process them
find "$scan_dir" -type f \( -iname \*.mp4 -o -iname \*.mkv -o -iname \*.avi -o -iname \*.mov -o -iname \*.flv -o -iname \*.wmv \) | while read file; do
    subdir=$(dirname "$file" | sed "s|^$scan_dir/||")
    filename=$(basename "$file")
    length=$(get_video_length "$file")
    echo "$subdir,$filename,$length" >> "$output_file"
done

echo "CSV file has been created: $output_file"