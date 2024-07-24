#!/bin/sh

# Marker directory
MARKER_DIR="/tmp/markers"
mkdir -p $MARKER_DIR

# Ensure the download directory exists
mkdir -p /tmp/download
cd /tmp/download

# Download files
echo "Downloading required files..."
curl -L -o GLTollGate.zip "https://github.com/chGoodchild/GLTollGate/archive/refs/tags/v0.0.1.zip"
curl -L -o nodogsplash_5.0.0-1_mips_24kc.ipk "https://github.com/chGoodchild/GLTollGate/releases/download/v0.0.1/nodogsplash_5.0.0-1_mips_24kc.ipk"

# Unpack the zip file
echo "Unpacking GLTollGate.zip..."
unzip -o GLTollGate.zip

# Move to the unpacked directory (adjust the directory name if needed)
cd GLTollGate-0.0.1

is_package_installed() {
    local package_name="$1"
    if opkg list-installed | grep -q "^$package_name "; then
        echo "$package_name is already installed."
        return 0
    else
        echo "$package_name is not installed."
        return 1
    fi

}

install_packages_if_needed() {
    opkg update
    local package_name
    for package_name in "$@"; do
        if ! is_package_installed "$package_name"; then
            echo "Installing $package_name..."
            opkg install "$package_name"
            if [ $? -eq 0 ]; then
                echo "$package_name installed successfully."
            else
                echo "Failed to install $package_name."
            fi
        fi
    done
}

# Install dependencies
echo "Installing dependencies..."
# install_packages_if_needed libmicrohttpd libpthread jq iptables-legacy
install_packages_if_needed jq
# ln -sf /usr/sbin/iptables-legacy /usr/sbin/iptables

# Install and start nodogsplash
if [ ! -f $MARKER_DIR/nodogsplash_installed ]; then
    opkg remove nodogsplash
    opkg install /tmp/download/nodogsplash_5.0.0-1_mips_24kc.ipk
    service nodogsplash start
    service nodogsplash status
    logread | grep nodogsplash
    touch $MARKER_DIR/nodogsplash_installed
fi

# Copy nodogsplash config and other necessary files, scripts, starting services, etc.
# Additional steps would be similar to those from the previous script, but adapted to local execution.

echo "Setup completed."

