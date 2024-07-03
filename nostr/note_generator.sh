#!/bin/bash

# Path to the JSON file with keys
JSON_FILE="nostr_keys.json"

# Extract public and private keys using jq
PUBLIC_KEY=$(jq -r '.npub' $JSON_FILE)
PRIVATE_KEY=$(jq -r '.nsec' $JSON_FILE)

CONTENT="Hello, Nostr!"  # Content of the note

# Create Event
CREATED_AT=$(date +%s)
EVENT=$(printf '{"id":"","pubkey":"%s","created_at":%s,"kind":1,"tags":[],"content":"%s","sig":""}' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Serialize Event
SERIALIZED_EVENT=$(printf '[0,"%s",%s,1,[],"%s"]' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Create Event ID
EVENT_ID=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 | awk '{print $2}')

# Convert private key from hex to binary, encode to Base64, then decode it and store in a temporary file
echo -n $PRIVATE_KEY | xxd -r -p | base64 > /tmp/private_key_base64.txt
base64 -d /tmp/private_key_base64.txt > /tmp/private_key.bin

# Confirm file creation and permissions
ls -l /tmp/private_key.bin
cat /tmp/private_key_base64.txt
sudo cat /tmp/private_key.bin

# Sign Event using the temporary file method
SIGNATURE=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 -sign /tmp/private_key.bin | xxd -p -c 256)

# Output signature to check it
echo "Signature: $SIGNATURE"

# Clean up: remove the temporary private key files
rm /tmp/private_key.bin /tmp/private_key_base64.txt

# Update Event with ID and Signature
EVENT=$(echo $EVENT | jq --arg id "$EVENT_ID" --arg sig "$SIGNATURE" '.id = $id | .sig = $sig')

# Convert the updated event JSON to a single line format suitable for websocket transmission
EVENT_JSON=$(echo $EVENT | jq -c .)

# Call publish.sh and pass JSON and relays as arguments
# ./publish.sh "$EVENT_JSON"

echo $EVENT_JSON

