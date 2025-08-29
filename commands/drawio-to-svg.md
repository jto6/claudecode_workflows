# Draw.io to SVG Converter - /drawio-to-svg

Convert Draw.io (.drawio) files to SVG format using the Draw.io CLI.

## Usage
```
/drawio-to-svg [file_or_directory]
```

## Description

This command converts Draw.io files to SVG format with intelligent processing:

- **Single file**: Converts the specified .drawio file to .svg in the same directory
- **Directory**: Converts all .drawio files in the directory that either:
  - Do not already have a corresponding .svg file, OR  
  - Are newer than their existing .svg file
- **No argument**: Searches the entire repository for .drawio files and applies directory logic

## Implementation

```bash
#!/bin/bash

# Function to convert a single drawio file to svg
convert_drawio_file() {
    local drawio_file="$1"
    local svg_file="${drawio_file%.drawio}.svg"
    
    echo "Converting $drawio_file to $svg_file"
    drawio --export --format svg --output "$svg_file" "$drawio_file"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully converted: $svg_file"
    else
        echo "✗ Failed to convert: $drawio_file"
        return 1
    fi
}

# Function to check if conversion is needed
needs_conversion() {
    local drawio_file="$1"
    local svg_file="${drawio_file%.drawio}.svg"
    
    # Convert if SVG doesn't exist
    if [ ! -f "$svg_file" ]; then
        return 0
    fi
    
    # Convert if drawio file is newer than SVG
    if [ "$drawio_file" -nt "$svg_file" ]; then
        return 0
    fi
    
    return 1
}

# Function to process directory
process_directory() {
    local dir="$1"
    local converted_count=0
    local skipped_count=0
    
    find "$dir" -name "*.drawio" -type f | while read -r drawio_file; do
        if needs_conversion "$drawio_file"; then
            if convert_drawio_file "$drawio_file"; then
                ((converted_count++))
            fi
        else
            echo "⏭  Skipping (up to date): $drawio_file"
            ((skipped_count++))
        fi
    done
    
    echo ""
    echo "Conversion summary:"
    echo "- Converted: $converted_count files"
    echo "- Skipped: $skipped_count files"
}

# Main logic
main() {
    # Check if drawio CLI is available
    if ! command -v drawio &> /dev/null; then
        echo "Error: drawio CLI is not installed or not in PATH"
        echo "Install it with: npm install -g @draw.io/drawio-desktop"
        return 1
    fi
    
    if [ $# -eq 0 ]; then
        # No arguments - search entire repository
        echo "Searching for .drawio files in repository..."
        process_directory "."
    elif [ -f "$1" ] && [[ "$1" == *.drawio ]]; then
        # Single file conversion
        if needs_conversion "$1"; then
            convert_drawio_file "$1"
        else
            echo "⏭  File is up to date: $1"
        fi
    elif [ -d "$1" ]; then
        # Directory conversion
        echo "Processing directory: $1"
        process_directory "$1"
    else
        echo "Error: '$1' is not a valid .drawio file or directory"
        return 1
    fi
}

main "$@"
```

## Examples

Convert a single file:
```bash
/drawio-to-svg diagram.drawio
```

Convert all files in a directory:
```bash
/drawio-to-svg docs/diagrams/
```

Convert all files in the repository:
```bash
/drawio-to-svg
```

## Dependencies

- **Draw.io CLI**: Install with `npm install -g @draw.io/drawio-desktop`
- The command checks for Draw.io CLI availability and provides installation instructions if missing

## Features

- **Smart conversion**: Only converts when necessary (file missing or outdated)
- **Batch processing**: Handles multiple files efficiently
- **Repository-wide search**: Finds all .drawio files when no path specified
- **Progress feedback**: Shows conversion status and summary
- **Error handling**: Graceful handling of missing dependencies or invalid files