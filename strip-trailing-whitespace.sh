#!/bin/bash

# Strip trailing whitespace and remove BOM from source files
# Usage: ./strip-trailing-whitespace.sh [directory]

set -e

DIR="${1:-.}"

# File extensions to process
EXTENSIONS=(
    "*.cpp" "*.h" "*.hpp" "*.c" "*.m" "*.mm"
    "*.py" "*.sh"
    "*.js" "*.ts"
    "*.json" "*.xml" "*.html" "*.css"
    "*.md" "*.txt"
    "*.cmake" "CMakeLists.txt"
)

# Directories to exclude
EXCLUDES=(
    "*/External/*"
    "*/BuildSystem/Default/*"
    "*/ImportCache/*"
    "*/IC/*"
    "*/Binaries/MalterlibLLVM/*"
    "*/Binaries/MalterlibSDK/*"
    "*/Binaries/MalterlibQt/*"
    "*/.git/*"
)

# Build find arguments for extensions
EXT_ARGS=()
for i in "${!EXTENSIONS[@]}"; do
    if [ $i -eq 0 ]; then
        EXT_ARGS+=("-name" "${EXTENSIONS[$i]}")
    else
        EXT_ARGS+=("-o" "-name" "${EXTENSIONS[$i]}")
    fi
done

# Build find arguments for excludes
EXCLUDE_ARGS=()
for excl in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=("!" "-path" "$excl")
done

# Run the command
# - Remove UTF-8 BOM (EF BB BF) from start of file
# - Remove trailing whitespace from all lines
LC_ALL=C find "$DIR" -type f \( "${EXT_ARGS[@]}" \) "${EXCLUDE_ARGS[@]}" -exec sed -i '' -e '1s/^\xef\xbb\xbf//' -e 's/[[:space:]]*$//' {} \;

echo "Done stripping trailing whitespace and BOM from: $DIR"
