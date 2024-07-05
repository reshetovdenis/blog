#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory> <outputfile>"
    exit 1
fi

input_dir=$1
output_file=$2

# Create a temporary directory for re-encoded files
temp_dir=$(mktemp -d)

# Iterate through numerically sorted subdirectories
for subdir in $(ls -d "$input_dir"/*/ | sort -V); do
    # Check if the directory contains .MP4 files
    mp4_files=("$subdir"*.MP4)
    if [ "${#mp4_files[@]}" -gt 0 ]; then
        # Randomly choose one .MP4 file
        random_file=${mp4_files[RANDOM % ${#mp4_files[@]}]}
        echo "file '$random_file'" >> "$temp_dir/filelist.txt"
    fi
done

# Check if the file list is not empty
if [ ! -s "$temp_dir/filelist.txt" ]; then
    echo "No MP4 files found in the specified directory."
    rm -rf "$temp_dir"
    exit 1
fi

# Use ffmpeg to concatenate the re-encoded files with a specified frame rate
ffmpeg -y -f concat -safe 0 -i "$temp_dir/filelist.txt" -c:v libx264 -c:a aac "$output_file"

# Clean up the temporary directory
rm -rf "$temp_dir"

echo "All files have been concatenated into $output_file"
