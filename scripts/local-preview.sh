#!/usr/bin/env bash

set -e  # Exit if any command fails

# Setup virtual environment using Python
if [ ! -d "venv" ]; then
    python3 -m venv venv
else
    echo "Virtual environment already exists."
fi

source venv/bin/activate

if ! pip show nodeenv > /dev/null 2>&1; then
    pip install nodeenv
else
    echo "nodeenv already installed."
fi

# Extract filepath from arguments and modify it's location
# Only one file is supported by npm run dev, other arguments should go
# unmodified
filepath="$(realpath $1)"
root="$(realpath "$(dirname "$0")")/.."

# Go to root of slidev-template repository
cd "$root"

if [ -L slides ]; then
    unlink slides
fi

ln -sr .. slides
# change path to e.g. './slides/<filepath>' format
filepath="slides/$(realpath --relative-to slides/ "$filepath")"

# Create Node.js virtual environment
nodeenv -p

# Run Slidev preview
npm install

shift

npm run dev "$filepath" "${args[@]}"
