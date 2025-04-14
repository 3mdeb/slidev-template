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

# Create Node.js virtual environment
nodeenv -p

# Run Slidev preview
npm install
npm run dev $@
