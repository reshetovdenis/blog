import os
import sys
import subprocess

# Usage example:
# python3 recode.py ~/tmp/test_videos ~/tmp/recoded

def preprocess_file(input_file, output_file):
    print("Preprocessing '{}' to '{}'".format(input_file, output_file))
    result = subprocess.run(['ffmpeg', '-i', input_file, '-c:v', 'libx264', '-preset', 'veryslow', '-crf', '22', '-c:a', 'aac', '-b:a', '192k', '-vf', 'fps=30,format=yuv420p', '-movflags', '+faststart', output_file])
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