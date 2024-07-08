#!/bin/bash

# Define the URL of the Python script
URL="https://github.com/chGoodchild/nostrKeys/releases/download/v0.0.3/generate_npub.py"
SEEDPHRASE="silk interest cruel fan chair bronze pond palace shield language trial citizen habit proof ankle book tourist book galaxy agent drum total idea frog"
SCRIPT="generate_npub.py"
OUTPUT_FILE="nostr_keys.json"

# Check if the Python script is already present and matches the expected SHA-256 hash
if [ -f "$SCRIPT" ]; then
    EXPECTED_HASH="160113dc186ca34c4e905375f659b0c37790d62e2b9002dc842360daaa36f056"
    CURRENT_HASH=$(sha256sum $SCRIPT | awk '{ print $1 }')

    if [ "$EXPECTED_HASH" != "$CURRENT_HASH" ]; then
        wget -q $URL -O $SCRIPT
        echo "Downloaded or updated generate_npub.py."
    fi
else
    wget -q $URL -O $SCRIPT
    echo "Downloaded generate_npub.py."
fi

# Ensure the script is executable
chmod +x $SCRIPT

# Run the script and save the output to a JSON file
python3 $SCRIPT "$SEEDPHRASE" > $OUTPUT_FILE

# Check if the JSON file was created successfully
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    echo "Nostr keys generated and saved to $OUTPUT_FILE"
else
    echo "Failed to generate Nostr keys."
fi

