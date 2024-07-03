#!/bin/bash

# Path to the JSON file with keys
JSON_FILE="nostr_keys.json"

# Extract public and private keys using jq
PUBLIC_KEY=$(jq -r '.npub' $JSON_FILE)
PRIVATE_KEY=$(jq -r '.nsec' $JSON_FILE)

# Configuration
RELAYS=(
    "wss://nos.lol"
    "wss://nostr.mom"
    "wss://nostr.oxtr.dev"
    "wss://relay.damus.io"
    "wss://relay.nostr.bg"
    "wss://nostr.bitcoiner.social"
    "wss://nostr.fmt.wiz.biz"
    "wss://nostr.wine"
    "wss://relay.noswhere.com"
    "wss://relay.nostr.band"
)

CONTENT="Hello, Nostr!"                                      # Content of the note

# Create Event
CREATED_AT=$(date +%s)
EVENT=$(printf '{"id":"","pubkey":"%s","created_at":%s,"kind":1,"tags":[],"content":"%s","sig":""}' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Serialize Event
SERIALIZED_EVENT=$(printf '[0,"%s",%s,1,[],"%s"]' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Create Event ID
EVENT_ID=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 | awk '{print $2}')

# Sign Event
# Correct the signing process using openssl
SIGNATURE=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 -sign <(echo -n $PRIVATE_KEY | xxd -r -p) | xxd -p -c 256)

# Update Event with ID and Signature
EVENT=$(echo $EVENT | jq --arg id "$EVENT_ID" --arg sig "$SIGNATURE" '.id = $id | .sig = $sig')

# Convert the updated event JSON to a single line format suitable for websocket transmission
EVENT_JSON=$(echo $EVENT | jq -c .)

# Publish Event to Relays
for RELAY in "${RELAYS[@]}"; do
    echo "Publishing to $RELAY"
    echo $EVENT_JSON | /usr/local/bin/websocat "$RELAY" --text
done

