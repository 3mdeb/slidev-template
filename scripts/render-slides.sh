#!/bin/bash
# Generate cheatsheet based on YAML input

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/env.sh"

render_slides() {
    local day
    local escaped_file
    local escaped_title
    local filename
    local input_arg
    local input_file_abs
    local input_file_rel
    local node_max_old_space
    local slidev_port
    local title

    # Remove any surrounding quotes from the argument to avoid breaking realpath
    input_arg=${1//\"/}

    if ! input_file_abs=$(realpath "$input_arg"); then
      error_exit "Could not resolve path for $input_arg"
    fi

    if [ ! -f "$input_file_abs" ]; then
      error_exit "$input_arg doesn't exist"
    fi

    input_file_rel=$(realpath --relative-to "$PWD/slidev-template" "$input_file_abs")
    if [ -z "$input_file_rel" ]; then
      error_exit "Couldn't compute relative path for $input_file_abs"
    fi

    # Derive other necessary variables from the input_file
    filename=$(basename "$input_file_abs")
    filename=${filename%.*}
    day=${filename:0:1}
    title=${SLIDES_TITLE:-3mdeb Presentation}
    title=${title//\"/}
    copyright=${COPYRIGHT:-3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0}
    copyright=${copyright//\"/}

    # Escape strings for sed
    escaped_file=$(printf '%s\n' "$input_file_rel" | sed -e 's/[\/&$]/\\&/g')
    escaped_title=$(printf '%s\n' "$title" | sed -e 's/[\/&$]/\\&/g')

    # Create temporary markdown file using the slide template
    sed -e "s/<SRC>/$escaped_file/g" -e "s/<DAY>/$day/g" -e "s/<COPYRIGHT>/$copyright/g" -e "s/<TITLE>/$escaped_title/g" \
      slides-template.md >slidev-template/slides.md
    cp slidev-template/vite.config.ts .

    slidev_port=${SLIDEV_PORT:-8000}
    node_max_old_space=${SLIDEV_NODE_MAX_OLD_SPACE:-4096}

    if command -v python3 >/dev/null 2>&1; then
      if ! python3 - "$slidev_port" <<'PY'
import socket
import sys

port = int(sys.argv[1])
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    s.bind(("0.0.0.0", port))
except OSError:
    sys.exit(1)
finally:
    s.close()
PY
      then
        print_error "Port $slidev_port is already in use. Set SLIDEV_PORT to a free port."
        exit 1
      fi
    fi

    docker run -it --rm --user $(id -u):$(id -g) \
      -v "$PWD:/repo" \
      -p "$slidev_port":8000 \
      -e NODE_OPTIONS=--max-old-space-size="$node_max_old_space" \
      "$PLAYWRIGHT_IMAGE" \
      bash -c "cd /repo/slidev-template && npm run dev slides.md -- -o false -p 8000 --remote --force"

    # Clean up temporary markdown file
    rm slidev-template/slides.md
    rm vite.config.ts
}

check_dependencies() {
  docker run -it --rm --user $(id -u):$(id -g) \
    -v "$PWD:/repo" \
    "$PLAYWRIGHT_IMAGE" \
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

Environment Variables:
  SLIDES_TITLE              Title for the presentation (default: 3mdeb Presentation)
  SLIDEV_PORT               Port for dev server (default: 8000)
  SLIDEV_NODE_MAX_OLD_SPACE Node.js max old space size in MB (default: 4096)
  COPYRIGHT                 Copyright string for footer (default: 3mdeb Sp. z o.o. Licensed under the CC BY-SA 4.0)
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

# Create symlink for slides to access parent directory resources (images, etc.)
if [ -L "slidev-template/slides" ]; then
  unlink slidev-template/slides
fi

if ! ln -sr . slidev-template/slides; then
  error_exit "Couldn't create slidev-template/slides symlink"
fi

# Call the function with the provided YAML file
render_slides "$1"
