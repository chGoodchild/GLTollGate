#!/bin/bash

# Define the URL of the Python script
URL="https://github.com/chGoodchild/nostrKeys/releases/download/v0.0.1/generate_npub.py"
SCRIPT="generate_npub.py"
OUTPUT_FILE="nostr_keys.json"

# Download the Python script quietly
wget -q $URL -O $SCRIPT

# Check if the download was successful
if [ -f "$SCRIPT" ]; then
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
else
    echo "Failed to download generate_npub.py."
fi

