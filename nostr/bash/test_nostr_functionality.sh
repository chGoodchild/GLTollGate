#!/bin/bash

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

# Run note_generator.sh
echo "Running note_generator.sh..."
./note_generator.sh
check_file "send.json"

# Run publish.sh
echo "Running publish.sh..."
PUBLISH_OUTPUT=$(./publish.sh)
if [[ "$PUBLISH_OUTPUT" == *'["OK",'* ]]; then
    echo "SUCCESS: publish.sh ran successfully and the event was accepted by the relay."
else
    echo "ERROR: publish.sh failed or the event was not accepted by the relay."
    exit 1
fi

# Run fetch_notes.sh
echo "Running fetch_notes.sh..."
FETCH_OUTPUT=$(./fetch_notes.sh)
if [[ "$FETCH_OUTPUT" == *'Note Content:'* ]]; then
    echo "SUCCESS: fetch_notes.sh ran successfully and the event was fetched."
else
    echo "ERROR: fetch_notes.sh did not fetch the expected event."
    exit 1
fi

echo "All tests passed successfully."

