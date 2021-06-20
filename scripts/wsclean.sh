#!/bin/bash

# - Locate all Swift files
# - Strip sll whitespace from a line
# - If no differene after edit, remove backup file
find . -name '*.swift' -print | while IFS='' read -r LINE; do
    sed -e 's/^[ ][ ]*$//' -i '.old' "${LINE}"
    if diff "${LINE}.old" "${LINE}"; then
        rm "${LINE}.old"
    else
        echo "-- ${LINE}"
    fi
done
