#!/bin/bash

# Define the URL for the websocat binary
WEBSOCAT_URL="https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl"
WEBSOCAT_BIN="websocat"
INSTALL_DIR="/usr/local/bin/"
EXPECTED_WEBSOCAT_VERSION="v1.13.0"

# Function to check if a command exists
function command_exists() {
    type "$1" &> /dev/null
}

# Function to install packages only if they are not already installed
function install_packages_if_needed() {
    local packages=("$@")
    local to_install=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" &> /dev/null; then
            to_install+=("$package")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "Installing: ${to_install[*]}"
        sudo apt-get install -y "${to_install[@]}"
    else
        echo "All packages are already installed."
    fi
}

# Function to update package lists if not updated today
function update_package_lists_if_needed() {
    local update_marker="/var/lib/apt/periodic/update-success-stamp"

    if [ ! -f "$update_marker" ] || [ "$(date +%Y-%m-%d -r "$update_marker")" != "$(date +%Y-%m-%d)" ]; then
        echo "Running apt-get update..."
        sudo apt-get update
    else
        echo "apt-get update has already been run today."
    fi
}

function install_websocat() {
    if [ -x "$INSTALL_DIR$WEBSOCAT_BIN" ]; then
        INSTALLED_VERSION=$($INSTALL_DIR$WEBSOCAT_BIN --version 2>&1)
        if [[ "$INSTALLED_VERSION" == *"$EXPECTED_WEBSOCAT_VERSION"* ]]; then
            echo "Websocat $EXPECTED_WEBSOCAT_VERSION is already installed."
            return
        else
            echo "Updating Websocat to $EXPECTED_WEBSOCAT_VERSION."
        fi
    else
        echo "Installing Websocat $EXPECTED_WEBSOCAT_VERSION."
    fi

    # Download the websocat binary
    wget -q $WEBSOCAT_URL -O $WEBSOCAT_BIN

    # Make it executable
    chmod +x $WEBSOCAT_BIN

    # Move it to the install directory
    sudo mkdir -p $INSTALL_DIR
    sudo mv $WEBSOCAT_BIN $INSTALL_DIR

    echo "Websocat installed/updated successfully."
}

function install_secp256k1() {
    # Check if the secp256k1 library version 2.2.1 is already installed
    if [ -f "/usr/local/lib/libsecp256k1.so.2.2.1" ]; then
        echo "secp256k1 library version 2.2.1 is already installed."
        return
    else
        echo "Installing/updating the secp256k1 library."
    fi

    # Clone the secp256k1 repository into /tmp
    if [ ! -d "/tmp/secp256k1" ]; then
        cd /tmp
        git clone https://github.com/bitcoin-core/secp256k1.git
        cd secp256k1
    else
        cd /tmp/secp256k1
        git fetch --all
        git reset --hard origin/master
    fi

    # Fetch the latest changes and reset to the latest commit
    git fetch --all
    git reset --hard origin/master

    # Run the autogen script
    ./autogen.sh

    # Configure the build with Schnorr signatures and ECDH enabled
    ./configure --enable-module-schnorrsig --enable-module-ecdh

    # Build the library
    make

    # Optionally run the test suite
    make check

    # Install the library
    sudo make install
    echo "secp256k1 library has been installed/updated."
}

# Update package lists if needed
update_package_lists_if_needed

# Install required dependencies only if needed
install_packages_if_needed autoconf automake libtool git gcc g++ make

# Install Websocat
install_websocat

# Install secp256k1
install_secp256k1

