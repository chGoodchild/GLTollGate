#!/bin/bash

# Define the URL of the Python script
URL="https://github.com/chGoodchild/nostrKeys/releases/download/v0.0.3/generate_npub.py"
SEEDPHRASE="silk interest cruel fan chair bronze pond palace shield language trial citizen habit proof ankle book tourist book galaxy agent drum total idea frog"
SCRIPT="/tmp/generate_npub.py"
OUTPUT_FILE="$(dirname "$(realpath "$0")")/nostr_keys.json"


# Function to check if nostr_keys.json is valid
check_nostr_keys() {
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        REQUIRED_KEYS=("npub" "nsec" "nsec_hex" "npub_hex" "bip39_nsec")
        for key in "${REQUIRED_KEYS[@]}"; do
            value=$(jq -r --arg key "$key" '.[$key]' "$OUTPUT_FILE")
            if [ -z "$value" ] || [ "$value" == "null" ]; then
                echo "Error: Missing or empty value for $key in $OUTPUT_FILE"
                exit 1
            fi
        done
        echo "Nostr keys are already present and valid in $OUTPUT_FILE"
    else
        echo "Error: nostr_keys.json is not present or is empty, and Python is not available to generate new keys."
        exit 1
    fi
}

# Check if Python is installed
if command -v python3 &> /dev/null; then
    ./install/install_keygen.sh
    # Ensure the script is executable
    chmod +x $SCRIPT

    # Run the script and save the output to a JSON file
    python3 $SCRIPT "$SEEDPHRASE" > $OUTPUT_FILE

    # Check if the JSON file was created successfully
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        echo "Nostr keys generated and saved to $OUTPUT_FILE"
    else
        echo "Failed to generate Nostr keys."
        exit 1
    fi
else
    echo "Python is not installed. Checking for existing nostr_keys.json..."
    check_nostr_keys
fi

