#!/bin/bash

# Define file paths
JSON_FILE="nostr_keys.json"

# Extract keys and identifiers
PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$JSON_FILE")
PRIVATE_KEY_ID=$(jq -r '.nsec' "$JSON_FILE")
PEM_FILE="${PRIVATE_KEY_ID}.pem"

# Event data
CONTENT="Hello, Nostr!"
CREATED_AT=$(date +%s)

# Create the event JSON without id and sig
EVENT=$(jq -n --arg pubkey "$PUBLIC_KEY_HEX" --argjson created_at "$CREATED_AT" --arg content "$CONTENT" '{
    "id": "",
    "pubkey": $pubkey,
    "created_at": $created_at,
    "kind": 1,
    "tags": [],
    "content": $content,
    "sig": ""
}')

# Serialize the event data
SERIALIZED_EVENT="[0,\"$PUBLIC_KEY_HEX\",$CREATED_AT,1,[],\"$CONTENT\"]"

# Ensure the PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo "PEM file $PEM_FILE does not exist."
    exit 1
fi

# Sign the serialized event using the PEM file
SIGNATURE=$(echo -n "$SERIALIZED_EVENT" | openssl dgst -sha256 -sign "$PEM_FILE" | xxd -p -c 64 | tr -d '\n')

# Compute the event ID (hash of the serialized event)
EVENT_ID=$(echo -n "$SERIALIZED_EVENT" | openssl dgst -sha256 | awk '{print $2}')

# Update the event with the ID and signature
EVENT=$(echo "$EVENT" | jq --arg id "$EVENT_ID" --arg sig "$SIGNATURE" '.id = $id | .sig = $sig')

# Convert event to JSON and save to send.json
echo '["EVENT",' "$EVENT" ']' > send.json

# Output the event JSON
cat send.json

