#!/bin/bash

# Define the repository URL and directory
REPO_URL="https://github.com/bitcoin-core/secp256k1.git"
REPO_DIR="$HOME/secp256k1"

# Install necessary tools
sudo apt-get update
sudo apt-get install -y autoconf automake libtool git gcc make

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

# Prepare the build system
./autogen.sh

# Configure the library with recommended features
./configure --enable-module-recovery --enable-experimental

# Compile and install
make
sudo make install

echo "libsecp256k1 has been installed successfully."
