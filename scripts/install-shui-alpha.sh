#!/usr/bin/env bash

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Clone the GitHub repository
rm -rf /home/default/.shui
git clone https://github.com/alansari/frontend.git -b dev-SHUI /home/default/.shui
cd /home/default/.shui


# Create a Python virtual environment and activate it
python3 -m venv .venv && source .venv/bin/activate  


# Install the requirements
pip install -r requirements.txt


# Run the main Python file from the repository
python shui/main.py &
