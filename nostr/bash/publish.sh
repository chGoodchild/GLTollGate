#!/bin/bash

# Define the path for the event JSON file
JSON_FILE="/tmp/send.json"

./install/install_websocat.sh

# Read the event JSON from the send.json file
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: No event JSON provided"
    exit 1
fi

EVENT_JSON=$(cat $JSON_FILE)

# Ensure the event JSON is valid
if [ -z "$EVENT_JSON" ]; then
    echo "Error: Event JSON is empty"
    exit 1
fi

# Check if relays are passed as arguments
if [ -z "$1" ]; then
    echo "Error: No relays provided"
    exit 1
fi
IFS=',' read -r -a RELAYS <<< "$1"

echo "JSON being sent: $EVENT_JSON"

# Publish Event to Relays
success_count=0
total_relays=${#RELAYS[@]}
for RELAY in "${RELAYS[@]}"; do
    echo "Publishing to $RELAY..."
    RESPONSE=$(echo $EVENT_JSON | /usr/local/bin/websocat "$RELAY" --text)
    if [[ "$RESPONSE" == *'"OK"'* ]]; then
        echo "Success: Event accepted by $RELAY."
        ((success_count++))
    else
        echo "Error: Event not accepted by $RELAY. Response: $RESPONSE"
    fi
done

# Check if any publications succeeded
if [[ "$success_count" -eq 0 ]]; then
    echo "Error: All relay publications failed."
    exit 1
else
    echo "Success: Published to $success_count out of $total_relays relay(s)."
fi

