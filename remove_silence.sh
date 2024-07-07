#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

# Read input and output file names from command line arguments
input_file="$1"
output_file="$2"

# Temporary files
temp_audio="temp_audio.wav"
temp_trimmed_video="temp_trimmed_video.mp4"
silence_log="silence_log.txt"

# Step 1: Extract audio from the video
ffmpeg -i "$input_file" -q:a 0 -map a "$temp_audio" -y

# Step 2: Detect silence in the audio and log the details
ffmpeg -i "$temp_audio" -af silencedetect=noise=-50dB:d=0.05 -f null - 2> "$silence_log"

# Step 3: Parse silence log to find start and end silence points
start_silence=$(grep "silence_end" "$silence_log" | head -n 1 | awk '{print $5}')
end_silence=$(grep "silence_start" "$silence_log" | tail -n 1 | awk '{print $5}')

echo "start_silence"
echo $start_silence

echo "end_silence"
echo $end_silence

# Check if silence detection found silence points
if [ -z "$start_silence" ]; then
    start_silence=0
fi
if [ -z "$end_silence" ]; then
    duration=$(ffprobe -i "$input_file" -show_entries format=duration -v quiet -of csv="p=0")
    end_silence=$duration
fi

# Step 4: Trim the video using ffmpeg
ffmpeg -i "$input_file" -ss "$start_silence" -to "$end_silence" -c copy "$temp_trimmed_video" -y

# Step 5: Ensure the output file is correctly generated
if [ ! -f "$temp_trimmed_video" ]; then
    echo "Error: The trimmed video file was not created."
    exit 1
fi

# Step 6: Move the trimmed video to the final output file name
mv "$temp_trimmed_video" "$output_file"

# Clean up temporary files
#rm "$temp_audio" "$silence_log"

echo "Trimmed video saved as $output_file"
