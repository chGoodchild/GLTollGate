#!/bin/bash

# Define file paths
JSON_FILE="nostr_keys.json"
TMP_KEY="/tmp/private_key.bin"

# Extract keys
PUBLIC_KEY=$(jq -r '.npub' "$JSON_FILE")
PRIVATE_KEY=$(jq -r '.nsec_hex' "$JSON_FILE")

# Event data
CONTENT="Hello, Nostr!"
CREATED_AT=$(date +%s)

# Create Event
EVENT=$(printf '{"id":"","pubkey":"%s","created_at":%s,"kind":1,"tags":[],"content":"%s","sig":""}' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")
SERIALIZED_EVENT=$(printf '[0,"%s",%s,1,[],"%s"]' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Prepare private key
echo -n $PRIVATE_KEY | xxd -r -p > "$TMP_KEY"
chmod 600 "$TMP_KEY"

cat $TMP_KEY

ls -la $TMP_KEY

xxd $TMP_KEY
# or
hexdump -C $TMP_KEY




# Sign event
SIGNATURE=$(echo -n $SERIALIZED_EVENT | sudo openssl dgst -sha256 -sign "$TMP_KEY" | xxd -p -c 256)

# Clean up key
rm "$TMP_KEY"

# Update event with signature
EVENT_ID=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 | awk '{print $2}')
EVENT=$(echo $EVENT | jq --arg id "$EVENT_ID" --arg sig "$SIGNATURE" '.id = $id | .sig = $sig')

# Convert event to JSON
EVENT_JSON=$(echo $EVENT | jq -c .)

# Call publish.sh and pass JSON and relays as arguments
# ./publish.sh "$EVENT_JSON"

echo $EVENT_JSON

