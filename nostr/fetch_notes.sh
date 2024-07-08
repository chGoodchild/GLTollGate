#!/bin/bash

# Define the list of relay URLs and your public key
RELAYS=(
    "wss://orangesync.tech"
)
PUBLIC_KEY="npub1vfl7v8fgwxnv88u6n5t3pwsmzqg7xajclmtlfqncpaf2crefqr9qu2kruy"

# Create a subscription request
SUBSCRIPTION_ID="sub1"
SUBSCRIPTION_REQUEST=$(jq -c -n --arg id "$SUBSCRIPTION_ID" --arg key "$PUBLIC_KEY" '[ "REQ", $id, { "authors": [ $key ] } ]')

# Print the subscription request (for debugging)
echo "Subscription Request: $SUBSCRIPTION_REQUEST"

# Function to subscribe to a relay and listen for messages
subscribe_to_relay() {
    local RELAY=$1
    echo "Connecting to $RELAY"

    # Connect to the relay and send the subscription request
    (echo "$SUBSCRIPTION_REQUEST" | websocat "$RELAY" --text) | while read -r message; do
        echo "Received message from $RELAY: $message"
    done &
}

# Subscribe to each relay
for RELAY in "${RELAYS[@]}"; do
    subscribe_to_relay "$RELAY"
done

# Function to listen for messages from all relays
listen_for_messages() {
    while true; do
        websocat -k -s ${RELAYS[*]} --text --no-close | while read -r message; do
            echo "Received message: $message"
        done
        sleep 1
    done
}

# Start listening for messages
# listen_for_messages


# Wait for all background jobs to finish
wait

