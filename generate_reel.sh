#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <directory> <outputfile> <header>"
    exit 1
fi

input_dir=$1
output_file=$2
header=$3

global_timestamp=$(date +%s)
temp_dir="$HOME/tmp/video_generation_$global_timestamp"
mkdir -p "$temp_dir"
modulo_index=$(($(date +%j) % 5))

# Iterate through numerically sorted subdirectories
for subdir in $(ls -d "$input_dir"/*/ | sort -V); do
    # Check if the directory contains .MP4 files
    mp4_files=("$subdir"*.MP4)
    if [ "${#mp4_files[@]}" -gt 0 ]; then
        # Randomly choose one .MP4 file
        
        subdir_name=$(basename "$subdir")

        if [ "$subdir_name" -eq 1 ]; then
            # Pseudorandomly choose one .MP4 file for the first directory
            random_index=$((modulo_index % ${#mp4_files[@]}))
            random_file=${mp4_files[$random_index]}
        else
            # Randomly choose one .MP4 file for other directories
            random_file=${mp4_files[RANDOM % ${#mp4_files[@]}]}
        fi

        # Determine the overlay based on the subdirectory name
        case "$subdir_name" in
            1)
                overlay=""
                #overlay="header.png"
                #shift_left=0
                ;;
            2|3)
                overlay="question_1.png"
                shift_left=75
                ;;
            7)
                overlay="question_2.png"
                shift_left=75
                ;;
            11)
                overlay="answer.png"
                shift_left=75
                ;;
            *)
                overlay=""
                ;;
        esac

        file_timestamp=$(date +%s%N)

        if [ "$subdir_name" = "1" ]; then
            processed_file="$temp_dir/processed_${file_timestamp}_$(basename "$random_file")"
            ./overlay_text.sh "$random_file" "$processed_file" "$header"
            echo "file '$processed_file'" >> "$temp_dir/filelist.txt"
        else
            if [ -n "$overlay" ]; then
                processed_file="$temp_dir/processed_${file_timestamp}_$(basename "$random_file")"
                ./overlay.sh "$random_file" "$overlay" "$processed_file" "$shift_left"
                echo "file '$processed_file'" >> "$temp_dir/filelist.txt"
            else
                echo "file '$random_file'" >> "$temp_dir/filelist.txt"
            fi
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
