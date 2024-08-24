#!/bin/sh

# Define file paths and constants
OUTPUT_FILE="/tmp/send.json"

# Function to generate encrypted DM JSON using nostril
generate_encrypted_dm_json() {
    sender_json_file=$1
    recipient_json_file=$2
    content=$3

    # Extract keys from the provided JSON file for sender
    PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$sender_json_file")
    
    # Extract recipient public key from the recipient JSON file
    RECIPIENT_PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$recipient_json_file")

    # Using nostril to generate the encrypted DM
    content_file=$(mktemp)
    echo "$3" > "$content_file"
    valgrind ./nostril --dm "$RECIPIENT_PUBLIC_KEY_HEX" \
              --content "$(cat $content_file)" \
              --sec "$PRIVATE_KEY_HEX" \
              --kind 14 \
              --envelope \
              --created-at $(date +%s) 2> $OUTPUT_FILE
    rm "$content_file"

    cat $OUTPUT_FILE

}

# Main execution flow, check for required arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <sender_json_file> <recipient_json_file> <message>"
    exit 1
else
    generate_encrypted_dm_json "$1" "$2" "$3"
fi

