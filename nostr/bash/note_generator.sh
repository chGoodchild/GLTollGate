#!/bin/bash

# Define file paths
JSON_FILE="nostr_keys.json"
SIGN_EVENT_C="sign_event.c"
SIGN_EVENT_BIN="sign_event"
EXPECTED_HASH="fecd306c2a478e774f21b64f61c643f786679233f9f75119a1e7f758a8f581df"

# Function to compile sign_event.c
compile_sign_event() {
    gcc "$SIGN_EVENT_C" -o "$SIGN_EVENT_BIN" -lsecp256k1 -lssl -lcrypto
    if [ $? -ne 0 ]; then
        echo "Failed to compile $SIGN_EVENT_C"
        exit 1
    fi
}

# Check if sign_event.c is already compiled and has the correct checksum
if [ -f "$SIGN_EVENT_BIN" ]; then
    CURRENT_HASH=$(sha256sum "$SIGN_EVENT_C" | awk '{ print $1 }')
    if [ "$EXPECTED_HASH" != "$CURRENT_HASH" ]; then
        echo "Checksum mismatch for $SIGN_EVENT_C, recompiling..."
        compile_sign_event
    fi
else
    echo "Compiling $SIGN_EVENT_C..."
    compile_sign_event
fi

# Extract keys and identifiers
PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$JSON_FILE")
PRIVATE_KEY_ID=$(jq -r '.nsec' "$JSON_FILE")

# Event data
CONTENT=${1:-"Hello, Nostr!"}  # Use the first argument as content, or default to "Hello, Nostr!"
CREATED_AT=$(date +%s)

# Create the serialized event data
SERIALIZED_EVENT="[0,\"$PUBLIC_KEY_HEX\",$CREATED_AT,1,[],\"$CONTENT\"]"

# Convert the serialized event to a hash
EVENT_HASH=$(echo -n "$SERIALIZED_EVENT" | openssl dgst -sha256 -binary | xxd -p -c 64)

# Use the sign_event binary to sign the hash
SIGNATURE=$(./"$SIGN_EVENT_BIN" "$EVENT_HASH" "$PRIVATE_KEY_HEX")

# Compute the event ID (hash of the serialized event)
EVENT_ID=$(echo -n "$SERIALIZED_EVENT" | openssl dgst -sha256 | awk '{print $2}')

# Create the event JSON with id and sig
EVENT=$(jq -n --arg id "$EVENT_ID" --arg pubkey "$PUBLIC_KEY_HEX" --argjson created_at "$CREATED_AT" --arg content "$CONTENT" --arg sig "$SIGNATURE" '{
    "id": $id,
    "pubkey": $pubkey,
    "created_at": $created_at,
    "kind": 1,
    "tags": [],
    "content": $content,
    "sig": $sig
}')

# Convert event to JSON and save to send.json
echo '["EVENT",' "$EVENT" ']' > send.json

# Output the event JSON
cat send.json

