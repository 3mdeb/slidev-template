#!/bin/bash
# Generate cheatsheet based on YAML input

set -e

gen_slides() {
    local day
    local escaped_file
    local escaped_title
    local filename
    local input_file
    local input_file_abs
    local input_file_rel
    local node_max_old_space
    local range
    local output_file
    local title

    # Extract slide information from YAML using yq with pipe as a separator
    IFS=$'\n' # Set Internal Field Separator to newline for reading line by line
    for entry in $(yq -r '.slides[] | [.input_file, .range, .output_file] | join("|")' "$1"); do
        # Read input_file, range, and output_file from pipe-separated format
        IFS='|' read -r input_file range output_file <<< "$entry"

        # Derive other necessary variables from the input_file
        if ! input_file_abs=$(realpath "$input_file"); then
          error_exit "Could not resolve path for $input_file"
        fi

        if [ ! -f "$input_file_abs" ]; then
          error_exit "$input_file doesn't exist"
        fi

        input_file_rel=$(realpath --relative-to "$PWD/slidev-template" "$input_file_abs")
        if [ -z "$input_file_rel" ]; then
          error_exit "Couldn't compute relative path for $input_file_abs"
        fi

        filename=$(basename "$input_file_abs")
        filename=${filename%.*}
        day=${filename:0:1}
        title=$(awk 'BEGIN{in_frontmatter=0} \
          /^---[\r\n]*$/ { if (in_frontmatter) exit; in_frontmatter=1; next } \
          in_frontmatter && /^title:[[:space:]]*/ { sub(/^title:[[:space:]]*/,"",$0); print; exit }' "$input_file_abs")
        if [ -z "$title" ]; then
          title="3mdeb Presentation"
        fi
        copyright=${COPYRIGHT:-3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0}
        copyright=${copyright//\"/}

        # Escape strings for sed
        escaped_file=$(printf '%s\n' "$input_file_rel" | sed -e 's/[\/&$]/\\&/g')
        escaped_title=$(printf '%s\n' "$title" | sed -e 's/[\/&$]/\\&/g')

        # Create temporary markdown file using the slide template
        sed -e "s/<SRC>/$escaped_file/g" -e "s/<DAY>/$day/g" -e "s/<COPYRIGHT>/$copyright/g" -e "s/<TITLE>/$escaped_title/g" \
          slides-template.md >slidev-template/slides.md

        cat slidev-template/slides.md

        node_max_old_space=${SLIDEV_NODE_MAX_OLD_SPACE:-4096}
        if [ -n "$USE_DOCKER" ]; then
          docker run -it --rm --user $(id -u):$(id -g) \
            -v "$PWD:/repo" \
            -e NODE_OPTIONS=--max-old-space-size="$node_max_old_space" \
            mcr.microsoft.com/playwright:v1.53.2-noble \
            bash -c "
              cd /repo/slidev-template && npm run export slides.md -- \
                --range $range --output output/$output_file -c
            "
        else
          cd slidev-template
          npm run export slides.md -- --range $range --output output/$output_file -c
          cd ..
        fi

        # Clean up temporary markdown file
        rm slidev-template/slides.md
    done
}

check_dependencies() {
  if [ -n "$USE_DOCKER" ]; then
    docker run -it --rm --user $(id -u):$(id -g) \
      -v "$PWD:/repo" \
      mcr.microsoft.com/playwright:v1.53.2-noble \
      bash -c "cd /repo/slidev-template && npm install"
  else
    cd slidev-template && npm install && cd ..
  fi
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
  --no-container            Run npm directly, not in container
  -v|--verbose              Enable trace output
  -h|--help                 Print this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --no-container)
        USE_DOCKER=
        shift
        ;;
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

USE_DOCKER="Y"
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
