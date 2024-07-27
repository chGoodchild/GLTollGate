#!/bin/bash

UPDATE_MARKER="/var/lib/apt/periodic/update-success-stamp"

# Update system and install necessary packages
# Check if the marker file exists and get today's date and the date of last update
if [ -f "$UPDATE_MARKER" ]; then
    LAST_UPDATE=$(date -r "$UPDATE_MARKER" +%Y%m%d)
    TODAY=$(date +%Y%m%d)

    # Compare the last update date to today's date
    if [ "$LAST_UPDATE" != "$TODAY" ]; then
        echo "Running 'sudo apt-get update' because it hasn't been run today..."
        sudo apt-get update
        sudo apt-get upgrade
    else
        echo "'sudo apt-get update' has already been run today."
    fi
else
    echo "Update marker file does not exist. Running 'sudo apt-get update'..."
    sudo apt-get update
    sudo apt-get upgrade
fi

# Function to install packages if they are not already installed
install_if_missing() {
    for pkg in "$@"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            echo "Installing $pkg..."
            sudo apt-get install -y "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done
}

# Use the function to install required packages
install_if_missing git libtool autoconf python3 python-is-python3 swig build-essential libssl-dev


# Check for Python 3 and install if not present
if ! command -v python3 &> /dev/null; then
    echo "Python 3 could not be found, installing..."
    sudo apt-get install -y python3
fi

# Ensure 'python' points to 'python3'
if ! command -v python &> /dev/null; then
    echo "'python' command not found, setting up 'python' to point to 'python3'..."
    sudo apt-get install -y python-is-python3
fi


# Clone the libwally-core repository
cd ~/


# Define the directory for the repository
REPO_DIR="$HOME/libwally-core"

# Check if the repository directory exists
if [ -d "$REPO_DIR" ]; then
    echo "Directory $REPO_DIR already exists. Pulling latest changes..."
    cd "$REPO_DIR"
    git pull
else
    echo "Cloning libwally-core..."
    git clone https://github.com/ElementsProject/libwally-core.git "$REPO_DIR"
    cd "$REPO_DIR"
fi

# Initialize and update submodules recursively
git submodule update --init --recursive

# Prepare the build system
./tools/autogen.sh

# Configure the build
./configure

# Compile and install
make
sudo make install

# Optional: Update the library cache
sudo ldconfig

