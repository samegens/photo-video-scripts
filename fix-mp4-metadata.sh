#!/bin/bash

set -euo pipefail

cd /home/sebastiaan/Dropbox/fotos

BACKUP_DIR="/home/sebastiaan/test/google-photos"

# Find all MP4 files in 2013, 2014, 2015
mapfile -t mp4_files < <(find 2013 2014 2015 -type f -iname "*.mp4")

for file in "${mp4_files[@]}"; do
    [ -z "$file" ] && continue

    # Get just the filename (without path)
    filename=$(basename "$file")
    
    # Find the original file in the backup directory
    original=$(find "$BACKUP_DIR" -type f -name "$filename" | head -n 1)
    
    if [ -z "$original" ]; then
        echo "WARNING: Original not found for $file, skipping"
        continue
    fi
    
    echo "Processing: $file"
    echo "  Original: $original"
    
    # Backup the processed file
    mv "$file" "$file.org"
    
    # Copy metadata from original to processed file without re-encoding
    if ffmpeg -nostats -loglevel error -i "$file.org" -i "$original" -map 0 -map_metadata 1 -c copy "$file"; then
        echo "  ✓ Metadata copied successfully"
        # Remove backup
        rm "$file.org"
    else
        echo "  ERROR: Failed to copy metadata"
        # Restore backup
        mv "$file.org" "$file"
    fi
done

echo ""
echo "Done!"
