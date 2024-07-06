#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory> <outputfile>"
    exit 1
fi

input_dir=$1
output_file=$2

global_timestamp=$(date +%s)
temp_dir="$HOME/tmp/video_generation_$global_timestamp"
mkdir -p "$temp_dir"

# Iterate through numerically sorted subdirectories
for subdir in $(ls -d "$input_dir"/*/ | sort -V); do
    # Check if the directory contains .MP4 files
    mp4_files=("$subdir"*.MP4)
    if [ "${#mp4_files[@]}" -gt 0 ]; then
        # Randomly choose one .MP4 file
        random_file=${mp4_files[RANDOM % ${#mp4_files[@]}]}
        subdir_name=$(basename "$subdir")

        # Determine the overlay based on the subdirectory name
        case "$subdir_name" in
            1)
                overlay="header.png"
                ;;
            2|3)
                overlay="question_1.png"
                ;;
            7)
                overlay="question_2.png"
                ;;
            11)
                overlay="answer.png"
                ;;
            *)
                overlay=""
                ;;
        esac

        file_timestamp=$(date +%s%N)

        if [ -n "$overlay" ]; then
            processed_file="$temp_dir/processed_${file_timestamp}_$(basename "$random_file")"
            ./overlay.sh "$random_file" "$overlay" "$processed_file"
            echo "file '$processed_file'" >> "$temp_dir/filelist.txt"
        else
            echo "file '$random_file'" >> "$temp_dir/filelist.txt"
        fi
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
