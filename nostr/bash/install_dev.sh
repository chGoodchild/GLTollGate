#!/bin/bash

# Define URLs and file paths
WEBSOCAT_URL="https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl"
WEBSOCAT_BIN="websocat"
WEBSOCAT_INSTALL_DIR="/usr/local/bin/"
EXPECTED_WEBSOCAT_VERSION="v1.13.0"
TOOLCHAIN_PREFIX="mips-linux-gnu"
SECP256K1_DIR="/tmp/secp256k1_mips"
INSTALL_DIR="/usr/local/mips-linux-gnu"

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

# Function to install the MIPS cross-compiler
function install_mips_cross_compiler() {
    echo "Installing MIPS cross-compiler..."
    install_packages_if_needed gcc-mips-linux-gnu g++-mips-linux-gnu
}

# Function to compile secp256k1 for MIPS
function setup_secp256k1_mips() {
    echo "Setting up secp256k1 for cross-compilation..."
    if [ ! -d "$SECP256K1_DIR" ]; then
        git clone https://github.com/bitcoin-core/secp256k1.git "$SECP256K1_DIR"
    fi
    cd "$SECP256K1_DIR"
    ./autogen.sh
    ./configure --host=${TOOLCHAIN_PREFIX} CC=${TOOLCHAIN_PREFIX}-gcc --prefix="$INSTALL_DIR" --enable-module-recovery
    make
    sudo make install
    cd -  # Return to the original directory
}

# Main execution flow
update_package_lists_if_needed
install_mips_cross_compiler
setup_secp256k1_mips
install_websocat

echo "Development environment setup complete."

