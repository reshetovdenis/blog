import os
import sys
import subprocess

def preprocess_file(input_file, output_file):
    print("Preprocessing '{}' to '{}'".format(input_file, output_file))
    # Step 1: Extract audio from the video
    temp_audio = output_file + '.wav'
    subprocess.run(['ffmpeg', '-i', input_file, '-q:a', '0', '-map', 'a', temp_audio, '-y'])
    
    # Step 2: Detect silence in the audio and log the details
    silence_log = output_file + '_silence.log'
    with open(silence_log, 'w') as log_file:
        subprocess.run(['ffmpeg', '-i', temp_audio, '-af', 'silencedetect=noise=-50dB:d=0.05', '-f', 'null', '-'], stderr=log_file)
    
    # Step 3: Parse silence log to find start and end silence points
    start_silence, end_silence = None, None
    with open(silence_log, 'r') as log_file:
        lines = log_file.readlines()
        for line in lines:
            if 'silence_end' in line:
                start_silence = line.split()[4]
                break
        for line in reversed(lines):
            if 'silence_start' in line:
                end_silence = line.split()[4]
                break
    
    if not start_silence or not end_silence:
        print("Could not find silence points in the log.")
        return
    
    # Step 4: Trim the video based on detected silence points
    result = subprocess.run([
        'ffmpeg', '-i', input_file, '-c:v', 'libx264', '-preset', 'veryslow', '-crf', '22', 
        '-c:a', 'aac', '-b:a', '192k', '-vf', 'fps=30,format=yuv420p', '-movflags', '+faststart', 
        '-ss', start_silence, '-to', end_silence, output_file
    ])
    
    # Clean up temporary files
    os.remove(temp_audio)
    os.remove(silence_log)
    
    if result.returncode != 0:
        print("Error processing file: {}".format(input_file))

def main(input_dir, output_dir):
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
                preprocess_file(input_file, output_file)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python process_videos.py <input_dir> <output_dir>")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_dir = sys.argv[2]

    main(input_dir, output_dir)
