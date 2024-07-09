#!/bin/bash

# Define file paths and constants
JSON_FILE="nostr_keys.json"
SIGN_EVENT_BIN_LOCAL="/tmp/sign_event_local"
SIGN_EVENT_BIN_MIPS="/tmp/sign_event_mips"
CHECKSUMS_FILE="checksums.json"
OUTPUT_FILE="/tmp/send.json"

# Check and download checksums.json if it doesn't exist
CHECKSUMS_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/checksums.json"
if [ ! -f "$CHECKSUMS_FILE" ]; then
    echo "Downloading checksums.json..."
    wget -q $CHECKSUMS_URL -O $CHECKSUMS_FILE
fi

# Function to ensure the binary is executable
function ensure_executable() {
    if [ -f "$1" ]; then
        if [ ! -x "$1" ]; then
            echo "Setting execute permission on $1"
            chmod +x $1
        fi
    fi
}

# Determine the architecture of the current system
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        BIN_PATH=$SIGN_EVENT_BIN_LOCAL
        EXPECTED_HASH=$(jq -r '.local_binary_checksum' $CHECKSUMS_FILE)
        DOWNLOAD_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/sign_event_local"
        ;;
    mips)
        BIN_PATH=$SIGN_EVENT_BIN_MIPS
        EXPECTED_HASH=$(jq -r '.mips_binary_checksum' $CHECKSUMS_FILE)
        DOWNLOAD_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/sign_event_mips"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Check if the binary exists and has the correct checksum
function verify_or_download_binary() {
    if [ -f "$BIN_PATH" ]; then
        CURRENT_HASH=$(sha256sum "$BIN_PATH" | awk '{print $1}')
        if [ "$EXPECTED_HASH" != "$CURRENT_HASH" ]; then
            echo "Checksum mismatch for $BIN_PATH, downloading..."
            download_binary
        else
            echo "$BIN_PATH exists and checksum is correct."
        fi
    else
        echo "$BIN_PATH does not exist, downloading..."
        download_binary
    fi
}

# Download the binary and verify checksum
function download_binary() {
    wget -q $DOWNLOAD_URL -O $BIN_PATH
    CURRENT_HASH=$(sha256sum $BIN_PATH | awk '{print $1}')
    if [ "$EXPECTED_HASH" != "$CURRENT_HASH" ]; then
        echo "Error: Checksum verification failed after download."
        exit 1
    fi
}

# Function to generate event and JSON
function generate_event_json() {
    # Extract keys and identifiers
    PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
    PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$JSON_FILE")

    # Ensure the binary is executable
    ensure_executable $BIN_PATH

    # Event data
    CONTENT=${1:-"Hello, Nostr!"}
    CREATED_AT=$(date +%s)
    SERIALIZED_EVENT="[0,\"$PUBLIC_KEY_HEX\",$CREATED_AT,1,[],\"$CONTENT\"]"
    EVENT_HASH=$(echo -n "$SERIALIZED_EVENT" | openssl dgst -sha256 -binary | xxd -p -c 64)
    SIGNATURE=$($BIN_PATH "$EVENT_HASH" "$PRIVATE_KEY_HEX")
    EVENT_ID=$(echo -n "$SERIALIZED_EVENT" | openssl dgst -sha256 | awk '{print $2}')

    # Create the event JSON
    EVENT=$(jq -n --arg id "$EVENT_ID" --arg pubkey "$PUBLIC_KEY_HEX" --argjson created_at "$CREATED_AT" --arg content "$CONTENT" --arg sig "$SIGNATURE" '{
        "id": $id,
        "pubkey": $pubkey,
        "created_at": $created_at,
        "kind": 1,
        "tags": [],
        "content": $content,
        "sig": $sig
    }')

    OUTPUT_FILE="/tmp/send.json"
    echo '["EVENT",' "$EVENT" ']' > $OUTPUT_FILE
    cat $OUTPUT_FILE
}

# Main execution flow
verify_or_download_binary
generate_event_json "$@"

