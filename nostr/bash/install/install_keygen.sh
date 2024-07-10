#!/bin/sh

# Define URLs and file paths
PYTHON_SCRIPT_URL="https://github.com/chGoodchild/nostrKeys/releases/download/v0.0.3/generate_npub.py"
PYTHON_SCRIPT="/tmp/generate_npub.py"
EXPECTED_HASH="160113dc186ca34c4e905375f659b0c37790d62e2b9002dc842360daaa36f056"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
OUTPUT_FILE="$SCRIPT_DIR/../nostr_keys.json"

# Check if Python is installed
if ! command -v python3 > /dev/null; then
    echo "Python3 is not installed. Please install Python3 to proceed."
    exit 1
fi

# Function to download and verify the Python script
download_and_verify_script() {
    echo "Downloading generate_npub.py..."
    wget -q $PYTHON_SCRIPT_URL -O $PYTHON_SCRIPT
    CURRENT_HASH=$(sha256sum $PYTHON_SCRIPT | awk '{ print $1 }')

    if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
        echo "Error: Checksum verification failed."
        exit 1
    fi

    chmod +x $PYTHON_SCRIPT
}

# Check if the Python script is already present and matches the expected SHA-256 hash
if [ -f "$PYTHON_SCRIPT" ]; then
    CURRENT_HASH=$(sha256sum $PYTHON_SCRIPT | awk '{ print $1 }')
    if [ "$CURRENT_HASH" != "$EXPECTED_HASH" ]; then
        echo "generate_npub.py is outdated or corrupted."
        download_and_verify_script
    else
        echo "generate_npub.py is up to date."
    fi
else
    download_and_verify_script
fi

