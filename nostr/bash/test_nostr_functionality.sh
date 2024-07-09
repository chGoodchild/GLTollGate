#!/bin/bash

# Enable debugging to show commands and their arguments as they are executed
# set -x

NOTE_CONTENT="Hello, Nostr! $(date +%s)"
NPUB="24b37f5ec0822b014c6ebb425641ac83529d47bce44d70272b3a95cf93f64cc1"
RELAYS="wss://puravida.nostr.land,wss://eden.nostr.land,wss://relay.snort.social,wss://orangesync.tech"

# RELAYS="wss://puravida.nostr.land,wss://eden.nostr.land,wss://relay.snort.social,wss://nostr.wine,wss://orangesync.tech,wss://atlas.nostr.land,wss://nostr-pub.wellorder.net,wss://nostr.mom,wss://relay.nostr.com.au,wss://filter.nostr.wine,wss://nostr.milou.lol,wss://relay.orangepill.dev,wss://relay.nostr.band,wss://relay.noswhere.com,wss://nostr.inosta.cc,wss://nos.lol,wss://nostr.bitcoiner.social,wss://relay.damus.io,wss://relay.nostr.bg,wss://nostr.oxtr.dev"

# Function to check if a file exists and is not empty
check_file() {
    echo -e "\n\n check_file $1"
    if [ -s "$1" ]; then
        echo "SUCCESS: $1 exists and is not empty."
    else
        echo "ERROR: $1 does not exist or is empty."
        exit 1
    fi
}

# Function to run the generate_keys.sh script
generate_keys() {
    echo -e "\n\n ./generate_keys.sh"
    ./generate_keys.sh
    check_file "nostr_keys.json"
}

# Function to run the note_generator.sh script
generate_note() {
    echo -e "\n\n ./note_generator.sh \"$NOTE_CONTENT\""
    ./note_generator.sh "$NOTE_CONTENT"
    check_file "/tmp/send.json"
}

# Function to run the publish.sh script
publish_events() {
    echo -e "\n\n ./publish.sh \"$RELAYS\""
    PUBLISH_OUTPUT=$(./publish.sh "$RELAYS")
    if [[ "$PUBLISH_OUTPUT" == *"Success: Published to"* ]]; then
        echo "SUCCESS: publish.sh ran successfully and the event was accepted by the relay."
    else
        echo "ERROR: publish.sh failed or the event was not accepted by the relay."
        exit 1
    fi
}

# Function to run the fetch_notes.sh script
fetch_notes() {
    echo -e "\n\n ./fetch_notes.sh \"$RELAYS\" \"$NPUB\""
    FETCH_OUTPUT=$(./fetch_notes.sh "$RELAYS" "$NPUB")
    if [[ "$FETCH_OUTPUT" == *'Note Content:'* ]]; then
        echo "SUCCESS: fetch_notes.sh ran successfully and the event was fetched."
    else
        echo "ERROR: fetch_notes.sh did not fetch the expected event."
        exit 1
    fi
}

# Main execution flow
generate_keys
generate_note
publish_events
fetch_notes

echo -e "\n\nAll tests passed successfully."

# Disable debugging to clean up output
# set +x

