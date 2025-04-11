#!/bin/bash

# Generate cheatsheet
# npm run export -- --range TBD --output cheatsheet.pdf

gen_slides() {
    local day
    local escaped_file
    local filename
    local csv_file=$1
    while IFS=',' read -r input_file range output_file
    do
      filename=$(basename "$input_file")
      filename=${filename%.*}
      day=${filename:0:1}
      # escape strings so they can be used in sed
      escaped_file=$(printf '%s\n' "$input_file" | sed -e 's/[\/&$]/\\&/g')
      temp_slides_md=$(mktemp -u -p ./)
      sed -e "s/<DAY>/$day/g" -e "s/<SRC>/$escaped_file/g" slides-template.md > "$temp_slides_md"
      mkdir -p output
      npm run export "$temp_slides_md" -- --range ${range} --output "output/$output_file" -c
      rm "$temp_slides_md"
    done < "$csv_file"
}

if [[ ! -f "$1" ]]; then
    echo "Usage: $0 <csv_file>"
    exit 1
fi

gen_slides "$1"
