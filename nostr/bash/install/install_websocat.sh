#!/bin/sh

# Define URLs and file paths
WEBSOCAT_URL="https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl"
WEBSOCAT_BIN="websocat"
WEBSOCAT_INSTALL_DIR="/usr/bin/"
EXPECTED_WEBSOCAT_VERSION="1.13.0"

# Check if Websocat is installed and if the version matches
if [ -x "$WEBSOCAT_INSTALL_DIR$WEBSOCAT_BIN" ]; then
    INSTALLED_VERSION=$($WEBSOCAT_INSTALL_DIR$WEBSOCAT_BIN --version | awk '{print $2}')
    if [ "$INSTALLED_VERSION" = "$EXPECTED_WEBSOCAT_VERSION" ]; then
        echo "Correct version of Websocat is already installed."
        exit 0
    else
        echo "Installed Websocat version: $INSTALLED_VERSION"
        echo "Websocat version mismatch. Installing correct version..."
    fi
else
    echo "Websocat is not installed. Installing..."
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Function to update package lists if not updated today for Debian-based systems
update_package_lists_if_needed_apt() {
    update_marker="/var/lib/apt/periodic/update-success-stamp"

    if [ ! -f "$update_marker" ] || [ "$(date +%Y-%m-%d -r "$update_marker")" != "$(date +%Y-%m-%d)" ]; then
        echo "Running apt-get update..."
        sudo apt-get update
    else
        echo "apt-get update has already been run today."
    fi
}

# Function to update package lists if not updated today for OpenWRT systems
update_package_lists_if_needed_opkg() {
    echo "Running opkg update..."
    opkg update
}

# Function to install Websocat
install_websocat() {
    # Download the websocat binary
    wget -q $WEBSOCAT_URL -O $WEBSOCAT_BIN

    # Make it executable
    chmod +x $WEBSOCAT_BIN

    # Move it to the install directory
    sudo mv $WEBSOCAT_BIN $WEBSOCAT_INSTALL_DIR

    echo "Websocat installed/updated successfully."
}

# Detect if the system is OpenWRT or Debian-based
if [ -f /etc/openwrt_release ]; then
    # System is OpenWRT
    PACKAGE_MANAGER="opkg"
elif [ -f /etc/debian_version ]; then
    # System is Debian-based
    PACKAGE_MANAGER="apt-get"
else
    echo "Unsupported system."
    exit 1
fi

# Main execution flow
if [ "$PACKAGE_MANAGER" = "apt-get" ]; then
    update_package_lists_if_needed_apt
elif [ "$PACKAGE_MANAGER" = "opkg" ]; then
    update_package_lists_if_needed_opkg
fi

install_websocat

echo "Websocat setup complete."

