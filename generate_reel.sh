#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory> <outputfile>"
    exit 1
fi

input_dir=$1
output_file=$2

# Create a temporary file to store the list of files to concatenate
temp_file=$(mktemp)

# Iterate through numerically sorted subdirectories
for subdir in $(ls -d "$input_dir"/*/ | sort -V); do
    # Check if the directory contains .MP4 files
    mp4_files=("$subdir"*.MP4)
    if [ "${#mp4_files[@]}" -gt 0 ]; then
        # Randomly choose one .MP4 file
        random_file=${mp4_files[RANDOM % ${#mp4_files[@]}]}
        # Add the chosen file to the temporary list
        echo "file '$random_file'" >> "$temp_file"
    fi
done

# Check if the temporary file is not empty
if [ ! -s "$temp_file" ]; then
    echo "No MP4 files found in the specified directory."
    rm "$temp_file"
    exit 1
fi

# Use ffmpeg to concatenate the selected files and re-encode them to avoid issues
ffmpeg -f concat -safe 0 -i "$temp_file" -c:v libx264 -c:a aac -strict experimental "$output_file"

# Clean up the temporary file
rm "$temp_file"

echo "All files have been concatenated into $output_file"