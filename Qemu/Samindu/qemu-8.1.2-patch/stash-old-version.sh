#!/bin/bash
# Enable nullglob so that globs that don't match expand to nothing
shopt -s nullglob

# Define the folder that holds old versions
OLD_VERSIONS_DIR="old-versions"

# Initialize max version to 0
max=0

# Loop through directories matching the pattern in old-versions
for d in "$OLD_VERSIONS_DIR"/dtrack-v*; do
    if [ -d "$d" ]; then
        # Extract just the folder name (e.g., dtrack_v3)
        base=$(basename "$d")
        # Remove the prefix "dtrack-v" to get the version number
        version=${base#dtrack-v}
        # Check if the version is a number and update max if it is larger
        if [[ "$version" =~ ^[0-9]+$ ]] && [ "$version" -gt "$max" ]; then
            max=$version
        fi
    fi
done

# Increment the maximum version number for the new folder
new_version=$((max + 1))
new_folder="$OLD_VERSIONS_DIR/dtrack-v$new_version"

echo "Creating new folder: $new_folder"
mkdir "$new_folder" || { echo "Failed to create $new_folder"; exit 1; }

# Loop through all directories in the current directory
for d in */; do
    # Remove trailing slash to get the directory name
    d=${d%/}
    # Skip the old-versions folder (we don't want to move it)
    if [ "$d" = "$OLD_VERSIONS_DIR" ]; then
        continue
    fi
    echo "Moving directory: $d -> $new_folder"
    mv "$d" "$new_folder"
done

echo "Operation completed."

