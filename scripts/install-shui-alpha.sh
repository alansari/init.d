#!/usr/bin/env bash

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user

# Check if the directory exists
if [ -d "/home/default/.shui" ]; then
    # If it exists, update the repository
    cd /home/default/.shui
    git fetch origin
    git checkout dev-SHUI
    git pull origin dev-SHUI
else
    # If it doesn't exist, clone the repository
    git clone https://github.com/Steam-Headless/frontend.git -b dev-SHUI /home/default/.shui
    cd /home/default/.shui
fi

# Create a Python virtual environment and activate it
python3 -m venv .venv && source .venv/bin/activate  


# Install the requirements
pip install -r requirements.txt


# Run the main Python file from the repository
python shui/main.py &
