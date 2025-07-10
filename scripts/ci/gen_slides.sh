#!/bin/bash
# Generate cheatsheet based on YAML input

set -e

gen_slides() {
    local day
    local escaped_file
    local filename
    local input_file
    local range
    local output_file

    # Extract slide information from YAML using yq with pipe as a separator
    IFS=$'\n' # Set Internal Field Separator to newline for reading line by line
    for entry in $(yq -r '.slides[] | [.input_file, .range, .output_file] | join("|")' "$1"); do
        # Read input_file, range, and output_file from pipe-separated format
        IFS='|' read -r input_file range output_file <<< "$entry"

        # Derive other necessary variables from the input_file
        filename=$(basename "$input_file")
        filename=${filename%.*}
        day=${filename:0:1}

        # Escape strings for sed
        escaped_file=$(printf '%s\n' "$input_file" | sed -e 's/[\/&$]/\\&/g')

        # Create temporary markdown file using the slide template
        sed -e "s/<SRC>/$escaped_file/g" -e "s/<DAY>/$day/g" slides-template.md > slides.md

        cat slides.md

        cd slidev-template
        npm run export ../slides.md -- --range $range --output output/$output_file -c
        cd ..

        # Clean up temporary markdown file
        rm slides.md
    done
}

check_dependencies() {
  cd slidev-template && npm install && cd ..
}


error_exit() {
  print_error "$1"
  exit 1
}

print_usage_error() {
  print_help
  error_exit "$1"
}

print_error() {
  local red="\033[31m"
  local reset="\033[0m"
  echo -e "${red}ERROR: $1${reset}"
}

print_help() {
cat <<EOF
$(basename "$0") [OPTION]... <slides_metadata>
Generates slides based on slides metadata file
Options:
  -v|--verbose              Enable trace output
  -h|--help                 Print this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -v|--verbose)
        set -x
        shift
        ;;
      -h|--help)
        print_help
        exit 0
        ;;
      -*)
        print_usage_error "Unknown option $1"
        ;;
      *)
        POSITIONAL_ARGS+=( "$1" )
        shift
        ;;
    esac
  done
}

parse_args "$@"
set -- "${POSITIONAL_ARGS[@]}"

if [ $# -ne 1 ]; then
  print_usage_error "Script accepts 1 positional arguments, got $#"
fi

if [ ! -f "$1" ]; then
  error_exit "$1 doesn't exist"
fi

if ! check_dependencies; then
  error_exit "Missing dependencies"
fi

# Call the function with the provided YAML file
gen_slides "$1"
