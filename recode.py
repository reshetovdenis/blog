#!/usr/bin/env python3
import os
import sys
import subprocess

def get_video_duration(input_file):
    result = subprocess.run(['ffprobe', '-loglevel', 'quiet', '-i', input_file, '-show_entries', 'format=duration', '-v', 'quiet', '-of', 'csv=p=0'], capture_output=True, text=True)
    return result.stdout.strip()

def preprocess_file(input_file, output_file, dB, speed):
    print("Preprocessing '{}' to '{}'".format(input_file, output_file))
    # Step 1: Extract audio from the video
    temp_audio = output_file + '.wav'
    subprocess.run(['ffmpeg', '-loglevel', 'quiet', '-i', input_file, '-q:a', '0', '-map', 'a', temp_audio, '-y'])
    
    # Step 2: Detect silence in the audio and log the details
    silence_log = output_file + '_silence.log'
    with open(silence_log, 'w') as log_file:
        subprocess.run(['ffmpeg', '-i', temp_audio, '-af', 'silencedetect=noise=-50dB:d=0.05', '-f', 'null', '-'], stderr=log_file)
    
    # Step 3: Parse silence log to find start and end silence points as pairs
    silence_intervals = []
    with open(silence_log, 'r') as log_file:
        lines = log_file.readlines()
        for line in lines:
            if 'silence_start' in line:
                start_time = line.split()[4]
            elif 'silence_end' in line:
                end_time = line.split()[4]
                silence_intervals.append((float(start_time), float(end_time)))
    
    video_duration = float(get_video_duration(input_file))
    
    # Determine start and end cropping points
    max_diff = 0.1
    start_silence = 0
    if silence_intervals and (abs(silence_intervals[0][0] - 0) < max_diff):
        start_silence = silence_intervals[0][1]

    end_silence = video_duration
    if (len(silence_intervals) > 1) and (abs(silence_intervals[-1][1] - video_duration) < max_diff):
        end_silence = silence_intervals[-1][0]
    
    # Step 4: Trim the video based on detected silence points
    result = subprocess.run([
        'ffmpeg', '-loglevel', 'quiet', '-i', input_file, 
        '-c:v', 'libx264', '-preset', 'veryslow', '-crf', '22', 
        '-c:a', 'aac', '-b:a', '192k', 
        '-af', f'volume={dB}dB,atempo={speed}',
        '-vf', f'fps=30,format=yuv420p,setpts=PTS/{speed}',
        '-movflags', '+faststart', 
        '-ss', str(start_silence), '-to', str(end_silence), output_file
    ])
    
    # Clean up temporary files
    os.remove(temp_audio)
    os.remove(silence_log)
    
    if result.returncode != 0:
        print("Error processing file: {}".format(input_file))

def main(input_dir, output_dir, dB, speed):
    # Ensure there is no trailing slash in input_dir and output_dir
    input_dir = input_dir.rstrip('/')
    output_dir = output_dir.rstrip('/')

    # Walk through the input directory
    for root, _, files in os.walk(input_dir):
        for file in files:
            if file.endswith('.MP4'):
                input_file = os.path.join(root, file)
                relative_path = os.path.relpath(input_file, input_dir)
                output_file = os.path.join(output_dir, relative_path)

                # Create the output directory if it doesn't exist
                os.makedirs(os.path.dirname(output_file), exist_ok=True)

                # Preprocess the file
                preprocess_file(input_file, output_file, dB, speed)

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python process_videos.py <input_dir> <output_dir> <dB> <speed>")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]
    dB = sys.argv[3]
    speed = sys.argv[4]

    main(input_dir, output_dir, dB, speed)
