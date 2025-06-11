#!/bin/bash
# Generate cheatsheet based on YAML input

render_slides() {
    local day
    local escaped_file
    local filename
    local input_file
    local range
    local output_file

    # Remove any surrounding quotes from the variables
    input_file=${1//\"/}

    # Derive other necessary variables from the input_file
    filename=$(basename "$input_file")
    filename=${filename%.*}
    day=${filename:0:1}

    # Escape strings for sed
    escaped_file=$(printf '%s\n' "$input_file" | sed -e 's/[\/&$]/\\&/g')

    # Create temporary markdown file using the slide template
    sed -e "s/<SRC>/$escaped_file/g" slides-template.md > slides.md

    docker run -it --rm --user $(id -u):$(id -g) \
      -v "$PWD:/repo" \
      -p 8000:8000 \
          mcr.microsoft.com/playwright:v1.53.0-noble \
      bash -c "cd /repo/slidev-template && npm run dev ../slides.md -- -o false -p 8000 --remote --force"

    # Clean up temporary markdown file
    rm slides.md
}

check_dependencies() {
  docker run -it --rm --user $(id -u):$(id -g) \
    -v "$PWD:/repo" \
    -p 8000:8000 \
    mcr.microsoft.com/playwright:v1.53.0-noble \
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

if ! check_dependencies; then
  error_exit "Missing dependencies"
fi

print_help() {
cat <<EOF
$(basename "$0") [OPTION]... [slides_filename]
EOF
}

if [ $# -ne 1 ]; then
  print_usage_error "Script accepts 1 positional arguments, got $#"
fi

# Call the function with the provided YAML file
render_slides "$1"
