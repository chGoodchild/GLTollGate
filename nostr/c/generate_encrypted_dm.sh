#!/bin/sh

# Define file paths and constants
JSON_FILE="nostr_keys.json"
OUTPUT_FILE="/tmp/send.json"

# Extract keys from the JSON file
PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$JSON_FILE")

# Function to generate encrypted DM JSON using nostril
generate_encrypted_dm_json() {
    recipient_pubkey=$1
    content=$2

    # Using nostril to generate the encrypted DM
    ./nostril --dm "$recipient_pubkey" \
              --content "$content" \
              --sec "$PRIVATE_KEY_HEX" \
              --kind 14 \
              --envelope \
              --created-at $(date +%s) > $OUTPUT_FILE

    cat $OUTPUT_FILE
}

# Main execution flow, check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <recipient_pubkey> <message>"
    exit 1
else
    generate_encrypted_dm_json "$1" "$2"
fi
