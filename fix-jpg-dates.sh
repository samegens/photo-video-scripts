#!/bin/bash

set -euo pipefail

# Find all JPG files in specified directories
mapfile -t jpg_files < <(find 2013 2014 2015 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \))

echo "Checking for JPG files without MediaCreateDate or CreateDate..."
echo ""

for file in "${jpg_files[@]}"; do
    [ -z "$file" ] && continue

    # Check if file has MediaCreateDate or CreateDate (get both in one call)
    dates=$(exiftool -MediaCreateDate -CreateDate -DateCreated -s -s -s "$file" 2>/dev/null)

    if [ -z "$dates" ]; then
        echo "NO MediaCreateDate or CreateDate: $file"
        
        # Get the directory name
        dir=$(dirname "$file")
        dirname=$(basename "$dir")
        
        # Extract date from directory name (format: yyyy-mm-dd)
        if [[ "$dirname" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2}) ]]; then
            date_str="${dirname:0:10}"
            echo "  Found date in directory: $date_str"
            
            # Set modification time to yyyy-mm-dd 12:00
            touch -t "${date_str//\-/}1200" "$file"
            echo "  ✓ Set modification time to $date_str 12:00"
        else
            echo "  WARNING: Directory name doesn't match yyyy-mm-dd format: $dirname"
        fi
        echo ""
    fi
done

echo "Done!"
