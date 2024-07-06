#!/bin/bash

# Read the event JSON from the send.json file
EVENT_JSON=$(cat send.json)

# Ensure the event JSON is valid
if [ -z "$EVENT_JSON" ]; then
    echo "No event JSON provided"
    exit 1
fi

# Configuration
RELAYS=(
    "wss://orangesync.tech"
)

echo "JSON being sent: $EVENT_JSON"

# Publish Event to Relays
for RELAY in "${RELAYS[@]}"; do
    echo "Publishing to $RELAY"
    echo $EVENT_JSON | /usr/local/bin/websocat "$RELAY" --text
done

