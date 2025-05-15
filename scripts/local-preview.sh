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

cd slidev-template

# Create Node.js virtual environment
nodeenv -p

# Run Slidev preview
npm install

# Extract filepath from arguments and modify it's location
# Only one file is supported by npm run dev, other arguments should go
# unmodified
filepath="../$1"
shift

npm run dev "$filepath" "${args[@]}"
