#!/bin/bash

# Define the home directory path and the repository URL
HOME_DIR=$HOME
REPO_URL="https://github.com/pedro-vicente/nostr_client_relay"
REPO_DIR="${HOME_DIR}/nostr_client_relay"

# Step into the home directory
cd $HOME_DIR

# Check if the directory exists
if [ -d "$REPO_DIR" ]; then
    echo "Repository already exists. Pulling latest changes..."
    cd $REPO_DIR
    git pull
    if [ $? -ne 0 ]; then
        echo "Failed to pull latest changes."
        exit 1
    fi
else
    # Clone the repository
    git clone $REPO_URL
    if [ $? -ne 0 ]; then
        echo "Failed to clone the repository."
        exit 1
    fi
    cd $REPO_DIR
fi

# Create build directory and initiate cmake build
cmake -S . -B build
if [ $? -ne 0 ]; then
    echo "CMake configuration failed."
    exit 1
fi

# Build the project
cd build
cmake --build .
if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

echo "Build completed successfully."
