#!/bin/bash

# Define the repository URL and the directory where it should be cloned
REPO_URL="https://github.com/chGoodchild/nostr_client_relay.git"
REPO_DIR="$HOME/nostr_client_relay"

# Check if the directory exists
if [ -d "$REPO_DIR" ]; then
    echo "Repository directory exists. Pulling latest changes..."
    cd "$REPO_DIR"
    # Pull latest changes
    git pull
else
    echo "Repository directory does not exist. Cloning repository..."
    # Clone the repository
    git clone "$REPO_URL" "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Check for any errors before proceeding
if [ $? -ne 0 ]; then
    echo "Git operation failed"
    exit 1
fi

# Prepare the build directory
echo "Preparing build directory..."
cmake -S . -B build

# Build the project
echo "Building the project..."
cd build
cmake --build .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build completed successfully."
else
    echo "Build failed."
    exit 1
fi
