#!/bin/bash

# Script: check_duplicate_prefixes.sh
# Purpose: Find directories with duplicate numeric prefixes (format: ###-filename)

check_duplicate_prefixes() {
    local search_dir="${1:-.}"  # Default to current directory if no argument provided

    # Declare associative arrays for tracking prefixes
    declare -A prefix_count
    declare -A prefix_dirs

    echo "Scanning directory: $search_dir"
    echo "Looking for directories matching pattern: ###-*"
    echo

    # Find directories matching the numeric prefix pattern
    while IFS= read -r -d '' dir; do
        # Extract just the directory name (not full path)
        dirname=$(basename "$dir")

        # Extract numeric prefix using parameter expansion
        if [[ "$dirname" =~ ^([0-9]+)-.* ]]; then
            prefix="${BASH_REMATCH[1]}"

            # Increment count for this prefix
            ((prefix_count["$prefix"]++))

            # Store directory names for this prefix
            if [[ -n "${prefix_dirs["$prefix"]}" ]]; then
                prefix_dirs["$prefix"]="${prefix_dirs["$prefix"]} $dirname"
            else
                prefix_dirs["$prefix"]="$dirname"
            fi
        fi
    done < <(find "$search_dir" -maxdepth 1 -type d -name '[0-9]*-*' -print0)

    # Check for duplicates and report results
    local duplicates_found=0

    echo "=== DUPLICATE PREFIX ANALYSIS ==="
    echo

    for prefix in "${!prefix_count[@]}"; do
        if [[ ${prefix_count["$prefix"]} -gt 1 ]]; then
            echo "DUPLICATE PREFIX FOUND: $prefix"
            echo "Count: ${prefix_count["$prefix"]} directories"
            echo "Directories:"

            # Display each directory with this prefix
            read -ra dirs_array <<< "${prefix_dirs["$prefix"]}"
            for dir in "${dirs_array[@]}"; do
                echo "  - $dir"
            done
            echo
            ((duplicates_found++))
        fi
    done

    if [[ $duplicates_found -eq 0 ]]; then
        echo "No duplicate prefixes detected."
        echo
        echo "=== ALL PREFIXES (UNIQUE) ==="
        for prefix in $(printf '%s\n' "${!prefix_count[@]}" | sort -n); do
            echo "Prefix $prefix: ${prefix_dirs["$prefix"]}"
        done
    else
        echo "Total duplicate prefixes found: $duplicates_found"
    fi
}

# Alternative implementation using sort and uniq
check_duplicates_alternative() {
    local search_dir="${1:-.}"

    echo "=== ALTERNATIVE METHOD USING SORT/UNIQ ==="
    echo

    # Extract prefixes and find duplicates
    find "$search_dir" -maxdepth 1 -type d -name '[0-9]*-*' -printf '%f\n' | \
    sed -n 's/^\([0-9]\+\)-.*/\1/p' | \
    sort | uniq -d | \
    while read -r duplicate_prefix; do
        echo "Duplicate prefix: $duplicate_prefix"
        echo "Directories:"
        find "$search_dir" -maxdepth 1 -type d -name "${duplicate_prefix}-*" -printf "  - %f\n"
        echo
    done
}

# Main execution
main() {
    local target_directory="${1:-.}"

    if [[ ! -d "$target_directory" ]]; then
        echo "Error: Directory '$target_directory' does not exist." >&2
        exit 1
    fi

    echo "Directory Prefix Duplicate Checker"
    echo "=================================="
    echo

    # Run primary check
    check_duplicate_prefixes "$target_directory"

    echo
    echo "=================================="

    # Run alternative method for verification
    check_duplicates_alternative "$target_directory"
}

# Execute main function with command line arguments
main "$@"

