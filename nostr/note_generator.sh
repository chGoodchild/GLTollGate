#!/bin/bash

# Define file paths
JSON_FILE="nostr_keys.json"

# Extract keys and identifiers
PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
PRIVATE_KEY_ID=$(jq -r '.nsec' "$JSON_FILE")
PEM_FILE="${PRIVATE_KEY_ID}.pem"

# Event data
CONTENT="Hello, Nostr!"
CREATED_AT=$(date +%s)

# Create Event
EVENT=$(printf '{"id":"","pubkey":"%s","created_at":%s,"kind":1,"tags":[],"content":"%s","sig":""}' "$PUBLIC_KEY_HEX" "$CREATED_AT" "$CONTENT")
SERIALIZED_EVENT=$(printf '[0,"%s",%s,1,[],"%s"]' "$PUBLIC_KEY_HEX" "$CREATED_AT" "$CONTENT")

# Ensure the PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo "PEM file $PEM_FILE does not exist."
    exit 1
fi

# Sign event using the PEM file
SIGNATURE=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 -sign "$PEM_FILE" | openssl base64 | tr -d '\n')

# Update event with signature
EVENT_ID=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 | awk '{print $2}')
EVENT=$(echo $EVENT | jq --arg id "$EVENT_ID" --arg sig "$SIGNATURE" '.id = $id | .sig = $sig')

# Convert event to JSON
EVENT_JSON=$(jq -n --arg id "$EVENT_ID" --arg pubkey "$PUBLIC_KEY_HEX" --argjson created_at $CREATED_AT --argjson kind 1 --arg content "$CONTENT" --arg sig "$SIGNATURE" '{id: $id, pubkey: $pubkey, created_at: $created_at, kind: $kind, tags: [], content: $content, sig: $sig}')

# Save to send.json
echo '["EVENT",' "$EVENT_JSON" ']' > send.json

# Output the event JSON
cat send.json

