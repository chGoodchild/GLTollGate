#!/bin/bash

# Define the URL of the Python script
URL="https://github.com/chGoodchild/nostrKeys/releases/download/v0.0.1/generate_npub.py"
SCRIPT="generate_npub.py"
OUTPUT_FILE="nostr_keys.json"

# Check if the Python script is already present and matches the expected SHA-256 hash
EXPECTED_HASH="809abf19807a4ebf0bdb7cf8a11649c1217c4e798a35c061030d9a0f197653c6"
CURRENT_HASH=$(sha256sum $SCRIPT | awk '{ print $1 }')

if [ ! -f "$SCRIPT" ] || [ "$EXPECTED_HASH" != "$CURRENT_HASH" ]; then
    # Download the Python script quietly
    wget -q $URL -O $SCRIPT
    echo "Downloaded or updated generate_npub.py."
fi

# Ensure the script is executable
chmod +x $SCRIPT

# Run the script and save the output to a JSON file
python3 $SCRIPT > $OUTPUT_FILE 2>/dev/null

# Check if the JSON file was created successfully
if [ -f "$OUTPUT_FILE" ]; then
    echo "Nostr keys generated and saved to $OUTPUT_FILE"
else
    echo "Failed to generate Nostr keys."
fi

