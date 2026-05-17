#!/bin/bash

# Project Setup Script
#
# This script initializes a new Python project structure.
# It creates a project directory with the specified name and sets up
# a standard layout including:
# - A main entry point (main.py)
# - A src/ directory for modules
# - A tests/ directory
# - A requirements.txt file
# - A .gitignore file
# - A README.md file
# - A logs/ directory
#
# Usage:
#   ./new_python_proj_setup.sh <project-name>
#
# Example:
#   ./new_python_proj_setup.sh my_new_project

set -e

# Check if a project name was provided
if [ -z "$1" ]; then
  echo "Usage: $0 project-name"
  exit 1
fi

# Set the project name
PROJECT_NAME=$1

# Create the project directory
echo ""
echo "Creating project directory: $PROJECT_NAME"
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Creating requirements.txt
echo ""
echo "Creating requirements.txt..."
touch requirements.txt

# Creating .gitignore
echo ""
echo "Creating .gitignore..."
cat <<EOL > .gitignore
# Virtual environment
venv/
__pycache__/
*.pyc

# Environment variables
.env

# MacOS system files
.DS_Store
EOL

# Create top-level README
echo ""
echo "Creating README.md..."
cat <<EOL > README.md
# $PROJECT_NAME

This project is a Python application built with a modular layout.

Replace this with your project description and instructions.
EOL

# Create the main entry point
echo ""
echo "Creating main.py..."
cat <<EOL > main.py
#!/usr/bin/env python3

from src import main_module

def main():
    print("Welcome to $PROJECT_NAME!")
    main_module.run()

if __name__ == '__main__':
    main()
EOL

# Make main.py executable
chmod +x main.py

# Create a src/ directory for your project modules
echo ""
echo "Creating src/ directory..."
mkdir src
cat <<EOL > src/__init__.py
# This file makes src a Python package.
from . import main_module
EOL

# Create a sample main_module in src/
echo ""
echo "Creating src/main.py..."
cat <<EOL > src/main.py
def run():
    print("This is the main module. Replace this with your core functionality.")
EOL

# Create additional placeholder modules if desired
for file in config.py module1.py module2.py; do
    echo ""
    echo "Creating src/\$file..."
    cat <<EOL > src/\$file
# \$file: Add your implementation details here.
EOL
done

# Create logs directory for log files
echo ""
echo "Creating logs directory..."
mkdir logs

# Create tests directory with a sample test file
echo ""
echo "Creating tests directory..."
mkdir tests
cat <<EOL > tests/__init__.py
# This file makes tests a Python package.
EOL

echo ""
echo "Creating tests/test_basic.py..."
cat <<EOL > tests/test_basic.py
def test_dummy():
    # Replace with actual tests for your modules
    assert True
EOL

# Final instructions for the user
echo ""
echo "Project '$PROJECT_NAME' created successfully."
echo "To set up your virtual environment and start coding, run these commands:"
echo "  cd $PROJECT_NAME"
echo "  python3 -m venv ~/venv"
echo "  source ~/venv/bin/activate"
echo "Happy coding!"
