#!/bin/bash

NOTE_CONTENT="Hello, Nostr! $(date +%s)"
NPUB="24b37f5ec0822b014c6ebb425641ac83529d47bce44d70272b3a95cf93f64cc1"
RELAYS="wss://orangesync.tech"

# Function to check if a file exists and is not empty
check_file() {
    if [ -s "$1" ]; then
        echo "SUCCESS: $1 exists and is not empty."
    else
        echo "ERROR: $1 does not exist or is empty."
        exit 1
    fi
}

# Run generate_keys.sh
echo "Running generate_keys.sh..."
./generate_keys.sh
check_file "nostr_keys.json"

# Run note_generator.sh with note content
echo "Running note_generator.sh..."
./note_generator.sh "$NOTE_CONTENT"
check_file "send.json"

# Run publish.sh with relay list
echo "Running publish.sh..."
PUBLISH_OUTPUT=$(./publish.sh "$RELAYS")
if [[ "$PUBLISH_OUTPUT" == *'["OK",'* ]]; then
    echo "SUCCESS: publish.sh ran successfully and the event was accepted by the relay."
else
    echo "ERROR: publish.sh failed or the event was not accepted by the relay."
    exit 1
fi

# Run fetch_notes.sh with relay list and npub
echo "Running fetch_notes.sh..."
FETCH_OUTPUT=$(./fetch_notes.sh "$RELAYS" "$NPUB")
if [[ "$FETCH_OUTPUT" == *'Note Content:'* ]]; then
    echo "SUCCESS: fetch_notes.sh ran successfully and the event was fetched."
else
    echo "ERROR: fetch_notes.sh did not fetch the expected event."
    exit 1
fi

echo "All tests passed successfully."

