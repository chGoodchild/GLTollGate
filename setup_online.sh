#!/bin/bash

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
unzip GLTollGate.zip

# Move to the unpacked directory (adjust the directory name if needed)
cd GLTollGate-0.0.1

# Step 1: Install nodogsplash package
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
