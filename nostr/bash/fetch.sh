#!/bin/bash

# Define the public key
npub="npub1yjeh7hkqsg4sznrwhdp9vsdvsdff63auu3xhqfet822ulylkfnqsgcpy8t"

# Configuration of relays
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

# JSON payload for requesting events
payload=$(cat <<EOF
{"req":"events","filters":[{"#p":"$npub"}]}
EOF
)

# Create a directory to save the fetched notes if it doesn't exist
mkdir -p fetched_notes

# Use websocat to fetch data from each relay
for RELAY in "${RELAYS[@]}"; do
    echo "Fetching from $RELAY"
    echo $payload | websocat --text -n "$RELAY" - | jq . > "fetched_notes/$(basename $RELAY).json"
done

echo "Fetched notes have been saved in the fetched_notes directory."

