#!/bin/sh

# Define the path for the event JSON file
JSON_FILE="/tmp/send.json"

# Call the install script for websocat
./install/install_websocat.sh

# Read the event JSON from the send.json file
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: No event JSON provided"
    exit 1
fi

EVENT_JSON=$(cat "$JSON_FILE")

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

# Convert the comma-separated relays string into an array
IFS=',' 
set -- $1
RELAYS=$@

echo "JSON being sent: $EVENT_JSON"

# Publish Event to Relays
success_count=0
total_relays=0
for RELAY in $RELAYS; do
    total_relays=$((total_relays + 1))
    echo "Publishing to $RELAY..."
    RESPONSE=$(echo "$EVENT_JSON" | /usr/local/bin/websocat "$RELAY" --text)
    echo "Response: $RESPONSE"
    case "$RESPONSE" in
        *'"OK"'*)
            echo "Success: Event accepted by $RELAY."
            success_count=$((success_count + 1))
            ;;
        *)
            echo "Error: Event not accepted by $RELAY. Response: $RESPONSE"
            ;;
    esac
done

# Check if any publications succeeded
if [ "$success_count" -eq 0 ]; then
    echo "Error: All relay publications failed."
    exit 1
else
    echo "Success: Published to $success_count out of $total_relays relay(s)."
fi

