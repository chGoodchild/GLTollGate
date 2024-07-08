#!/bin/bash

# Define the list of relay URLs and your public key
RELAYS=(
    "wss://orangesync.tech"
)
# PUBLIC_KEY="npub1yjeh7hkqsg4sznrwhdp9vsdvsdff63auu3xhqfet822ulylkfnqsgcpy8t"
PUBLIC_KEY="24b37f5ec0822b014c6ebb425641ac83529d47bce44d70272b3a95cf93f64cc1"

# Define the subscription ID and the timestamp to fetch events from
SUBSCRIPTION_ID="sub1"
CURRENT_TIMESTAMP=$(date +%s)
SINCE_TIMESTAMP=$((CURRENT_TIMESTAMP - 3600))

# Create a subscription request
SUBSCRIPTION_REQUEST=$(jq -c -n --arg id "$SUBSCRIPTION_ID" --arg key "$PUBLIC_KEY" --argjson since "$SINCE_TIMESTAMP" '[ "REQ", $id, { "authors": [ $key ], "since": $since } ]')

# Print the subscription request and timestamps (for debugging)
echo "Subscription Request: $SUBSCRIPTION_REQUEST"
echo "Current Timestamp: $CURRENT_TIMESTAMP"
echo "Since Timestamp: $SINCE_TIMESTAMP"

# Function to parse and print the notes from the relay messages
parse_and_print_notes() {
    while IFS= read -r message; do
        echo "Received message: $message"
        if echo "$message" | jq -e '.[0] == "EVENT"' > /dev/null; then
            event=$(echo "$message" | jq -c '.[1]')
            content=$(echo "$event" | jq -r '.content')
            echo "Note Content: $content"
        fi
    done
}

# Function to subscribe to a relay and listen for messages
subscribe_to_relay() {
    local RELAY=$1
    echo "Connecting to $RELAY"

    # Connect to the relay and send the subscription request
    (echo "$SUBSCRIPTION_REQUEST" | websocat "$RELAY" --text | parse_and_print_notes) &
}

# Subscribe to each relay
for RELAY in "${RELAYS[@]}"; do
    subscribe_to_relay "$RELAY"
done

# Wait for all background jobs to finish
wait

