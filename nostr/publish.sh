#!/bin/bash

# Get the event JSON from the first argument
EVENT_JSON=$1

# All remaining arguments are relays
shift
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

# Publish Event to Relays
for RELAY in "${RELAYS[@]}"; do
    echo "Publishing to $RELAY"
    echo $EVENT_JSON | /usr/local/bin/websocat "$RELAY" --text
done

