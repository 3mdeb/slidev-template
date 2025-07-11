#!/bin/bash
# Generate cheatsheet based on YAML input

render_slides() {
    local day
    local escaped_file
    local filename
    local input_file

    # Remove any surrounding quotes from the variables
    input_file=${1//\"/}
    input_file="slides/$(realpath --relative-to slidev-template/slides/ "$input_file")"
    # Derive other necessary variables from the input_file
    filename=$(basename "$input_file")
    filename=${filename%.*}
    day=${filename:0:1}

    # Escape strings for sed
    escaped_file=$(printf '%s\n' "$input_file" | sed -e 's/[\/&$]/\\&/g')

    # Create temporary markdown file using the slide template
    sed -e "s/<SRC>/$escaped_file/g" -e "s/<DAY>/$day/g" slides-template.md >slidev-template/slides.md

    docker run -it --rm --user $(id -u):$(id -g) \
      -e VITE_HOST=0.0.0.0 \
      -v "$PWD:/repo" \
      -p 8000:8000 \
          mcr.microsoft.com/playwright:v1.53.2-noble \
      bash -c "cd /repo/slidev-template && npm run dev slides.md -- -o false -p 8000 --remote --force"

    # Clean up temporary markdown file
    rm slidev-template/slides.md
}

check_dependencies() {
  docker run -it --rm --user $(id -u):$(id -g) \
    -e VITE_HOST=0.0.0.0 \
    -v "$PWD:/repo" \
    -p 8000:8000 \
    mcr.microsoft.com/playwright:v1.53.2-noble \
    bash -c "cd /repo/slidev-template && npm install"
  return $?
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
$(basename "$0") [OPTION]... <slide_file>
Generates slides
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

if [ -L "slidev-template/slides" ]; then
  unlink slidev-template/slides
fi

if ! ln -sr . slidev-template/slides; then
  error_exit "Couldn't create slidev-template/slides symlink"
fi

# Call the function with the provided YAML file
render_slides "$1"
