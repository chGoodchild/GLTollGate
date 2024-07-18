#!/bin/sh

# Get the directory of this script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Define architecture specific details
ARCH=$(uname -m)
CHECKSUMS_FILE="/tmp/checksums.json"
CHECKSUMS_URL="https://github.com/chGoodchild/TollGateNostrToolKit/releases/download/v0.0.5/checksums.json"

# Download the checksums file if it doesn't exist
if [ ! -f "$CHECKSUMS_FILE" ]; then
    echo "Downloading checksums.json..."
    wget -q $CHECKSUMS_URL -O $CHECKSUMS_FILE
fi

case $ARCH in
    x86_64)
        BINARY_URL="https://github.com/chGoodchild/TollGateNostrToolKit/releases/download/v0.0.5/RelayLink"
        BINARY_PATH="/tmp/RelayLink"
        ;;
    mips)
        BINARY_URL="https://github.com/chGoodchild/TollGateNostrToolKit/releases/download/v0.0.5/RelayLink_mips"
        BINARY_PATH="/tmp/RelayLink_mips"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Function to download and verify the binary
download_and_verify_binary() {
    echo "Downloading $BINARY_URL to $BINARY_PATH..."
    wget -q $BINARY_URL -O $BINARY_PATH
    CURRENT_HASH=$(sha256sum $BINARY_PATH | awk '{ print $1 }')
    
    if [ "$CURRENT_HASH" != "$(jq -r ".$(basename $BINARY_PATH)_checksum" $CHECKSUMS_FILE)" ]; then
        echo "Error: Checksum verification failed."
        exit 1
    fi

    chmod +x $BINARY_PATH
    echo "Installation and verification complete. $BINARY_PATH is ready to use."
}

# Check if the binary is already in the tmp directory and has the correct checksum
if [ -f "$BINARY_PATH" ]; then
    CURRENT_HASH=$(sha256sum $BINARY_PATH | awk '{ print $1 }')
    if [ "$CURRENT_HASH" = "$(jq -r ".$(basename $BINARY_PATH)_checksum" $CHECKSUMS_FILE)" ]; then
        echo "$BINARY_PATH is up to date."
        exit 0
    else
        download_and_verify_binary
    fi
else
    download_and_verify_binary
fi

