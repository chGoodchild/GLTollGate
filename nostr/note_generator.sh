#!/bin/bash

# Define file paths
JSON_FILE="nostr_keys.json"

# Extract keys and identifiers
PUBLIC_KEY=$(jq -r '.npub' "$JSON_FILE")
PRIVATE_KEY_ID=$(jq -r '.nsec' "$JSON_FILE") # Assuming 'nsec' contains the identifier
PEM_FILE="${PRIVATE_KEY_ID}.pem" # Constructs the PEM file name dynamically

# Event data
CONTENT="Hello, Nostr!"
CREATED_AT=$(date +%s)

# Create Event
EVENT=$(printf '{"id":"","pubkey":"%s","created_at":%s,"kind":1,"tags":[],"content":"%s","sig":""}' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")
SERIALIZED_EVENT=$(printf '[0,"%s",%s,1,[],"%s"]' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Ensure the PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo "PEM file $PEM_FILE does not exist."
    exit 1
fi

# Sign event using the PEM file
SIGNATURE=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 -sign "$PEM_FILE" | xxd -p -c 256)

# Update event with signature
EVENT_ID=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 | awk '{print $2}')
EVENT=$(echo $EVENT | jq --arg id "$EVENT_ID" --arg sig "$SIGNATURE" '.id = $id | .sig = $sig')

# Convert event to JSON
EVENT_JSON=$(jq -n --arg id "$EVENT_ID" --arg pubkey "$PUBLIC_KEY" --argjson created_at $CREATED_AT --argjson kind 1 --arg content "Hello, Nostr!" --arg sig "$SIGNATURE" '{id: $id, pubkey: $pubkey, created_at: $created_at, kind: $kind, tags: [], content: $content, sig: $sig}')

echo $EVENT_JSON

