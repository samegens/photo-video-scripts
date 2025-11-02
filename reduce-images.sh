#!/bin/bash

set -euo pipefail

# Get directory from argument or use current directory
DIR="${1:-.}"

# Check if directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Directory '$DIR' does not exist"
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v mogrify &> /dev/null || ! command -v identify &> /dev/null; then
    echo "Error: ImageMagick (mogrify and identify) is required but not installed"
    exit 1
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "Error: ffmpeg and ffprobe are required but not installed"
    exit 1
fi

echo "Processing images and videos in: $DIR"
echo ""

# Process JPG files
mapfile -t jpg_files < <(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \))
for file in "${jpg_files[@]}"; do
    [ -z "$file" ] && continue

    # Get image dimensions
    dimensions=$(identify -format "%w %h" "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Skipping $file (unable to read)"
        continue
    fi

    width=$(echo $dimensions | cut -d' ' -f1)
    height=$(echo $dimensions | cut -d' ' -f2)

    # Check if image needs resizing (larger than 1280x720)
    if [ "$width" -gt 1280 ] || [ "$height" -gt 720 ]; then
        echo "Resizing JPG: $file (${width}x${height} -> max 1280x720)"
        mogrify -resize 1280x720\> -quality 80 "$file"
    else
        echo "Skipping JPG: $file (already ${width}x${height})"
    fi
done

# Process PNG files
mapfile -t png_files < <(find "$DIR" -type f -iname "*.png")
for file in "${png_files[@]}"; do
    [ -z "$file" ] && continue

    # Get image dimensions
    dimensions=$(identify -format "%w %h" "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Skipping $file (unable to read)"
        continue
    fi

    width=$(echo $dimensions | cut -d' ' -f1)
    height=$(echo $dimensions | cut -d' ' -f2)

    # Check if image needs processing (larger than 1280x720)
    if [ "$width" -gt 1280 ] || [ "$height" -gt 720 ]; then
        echo "Converting PNG to JPG: $file (${width}x${height} -> max 1280x720)"
        mogrify -format jpg -resize 1280x720\> -quality 80 "$file"

        # Remove original PNG
        rm "$file"
        echo "Removed original PNG: $file"
    else
        echo "Skipping PNG: $file (already ${width}x${height})"
    fi
done

# Process MP4 files
mapfile -t mp4_files < <(find "$DIR" -type f -iname "*.mp4")
for file in "${mp4_files[@]}"; do
    [ -z "$file" ] && continue

    # Get video dimensions
    dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Skipping $file (unable to read)"
        continue
    fi

    width=$(echo $dimensions | cut -d'x' -f1)
    height=$(echo $dimensions | cut -d'x' -f2)

    # Check if video needs processing (larger than 1280x720)
    if [ "$width" -gt 1280 ] || [ "$height" -gt 720 ]; then
        echo "Reducing MP4: $file (${width}x${height} -> max 1280x720)"
        temp_file="${file}.tmp.mp4"
        if ffmpeg -nostats -loglevel error -i "$file" -map_metadata 0 -vf scale=1280:720 -c:v libx264 -crf 25 -preset medium -c:a copy "$temp_file"; then
            mv "$temp_file" "$file"
        else
            echo "ERROR: Failed to process $file"
            rm -f "$temp_file"
        fi
    else
        echo "Skipping MP4: $file (already ${width}x${height})"
    fi
done

echo ""
echo "Done!"