#!/bin/bash

# Define URLs and file paths
WEBSOCAT_URL="https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl"
WEBSOCAT_BIN="websocat"
WEBSOCAT_INSTALL_DIR="/usr/local/bin/"
EXPECTED_WEBSOCAT_VERSION="v1.13.0"

# Function to check if a command exists
function command_exists() {
    type "$1" &> /dev/null
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

# Function to install Websocat
function install_websocat() {
    if [ -x "$WEBSOCAT_INSTALL_DIR$WEBSOCAT_BIN" ]; then
        INSTALLED_VERSION=$($WEBSOCAT_INSTALL_DIR$WEBSOCAT_BIN --version 2>&1)
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
    sudo mkdir -p $WEBSOCAT_INSTALL_DIR
    sudo mv $WEBSOCAT_BIN $WEBSOCAT_INSTALL_DIR

    echo "Websocat installed/updated successfully."
}

# Main execution flow
update_package_lists_if_needed
install_websocat

echo "Websocat setup complete."

