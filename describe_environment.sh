#!/bin/bash

# Define the base directory
baseDir="$HOME/Desktop/ELK_Docker-main"  # Replace with your target directory

# Initialize an empty string to store the output
output=""

# Define file types to exclude
excluded_file_types=("tar" "ps1" "sh", "DS_Store")

# Function to build the directory structure output
get_directory_structure() {
    local path="$1"
    local indent="$2"

    # Append directories to output
    for dir in "$path"/*/; do
        if [ -d "$dir" ]; then
            dirName=$(basename "$dir")
            output+="${indent}|-- Folder: $dirName\n"
            get_directory_structure "$dir" "${indent}    "
        fi
    done

    # Append files to output
    for file in "$path"/*; do
        if [ -f "$file" ]; then
            fileName=$(basename "$file")
            output+="${indent}|-- File: $fileName\n"
        fi
    done
}

# Function to build file contents output
get_file_contents() {
    local path="$1"

    # Set IFS to handle file paths with spaces
    IFS=$'\n'

    # Use find with a loop to process files
    for file in $(find "$path" -type f); do
        # Get the file extension
        file_extension="${file##*.}"

        # Skip excluded file types
        if [[ " ${excluded_file_types[*]} " =~ " $file_extension " ]]; then
            output+="\n--- Skipping $file_extension file: $file ---\n"
            continue
        fi

        output+="\n--- Contents of $file ---\n"
        # Read the file content safely
        if content=$(<"$file"); then
            if [[ -n "$content" ]]; then
                output+="$content\n"
            else
                output+="[File is empty: $file]\n"
            fi
        else
            output+="[Error reading file: $file]\n"
        fi
    done

    # Reset IFS
    unset IFS
}

# Build the output
output+="Directory Structure:\n"
get_directory_structure "$baseDir" ""

output+="\nFile Contents:\n"
get_file_contents "$baseDir"

# Copy the output to the clipboard (requires `xclip` or `pbcopy`)
if command -v pbcopy >/dev/null; then
    echo -e "$output" | pbcopy
    echo "The directory structure and file contents have been copied to your clipboard."
elif command -v xclip >/dev/null; then
    echo -e "$output" | xclip -selection clipboard
    echo "The directory structure and file contents have been copied to your clipboard."
else
    echo -e "$output"
    echo "Clipboard functionality is not available. Install 'pbcopy' (macOS) or 'xclip' (Linux) to enable it."
fi
