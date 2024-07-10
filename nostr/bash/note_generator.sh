#!/bin/sh

# Define file paths and constants
JSON_FILE="nostr_keys.json"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
SIGN_EVENT_BIN_LOCAL="$SCRIPT_DIR/sign_event_local"
SIGN_EVENT_BIN_MIPS="$SCRIPT_DIR/sign_event_mips"
CHECKSUMS_FILE="$SCRIPT_DIR/checksums.json"
OUTPUT_FILE="/tmp/send.json"

# Check and download checksums.json if it doesn't exist
CHECKSUMS_URL="https://github.com/chGoodchild/nostrSigner/releases/download/v0.0.1/checksums.json"
if [ ! -f "$CHECKSUMS_FILE" ]; then
    echo "Downloading checksums.json..."
    wget -q $CHECKSUMS_URL -O $CHECKSUMS_FILE
fi

# Function to ensure the binary is executable
ensure_executable() {
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
        ;;
    mips)
        BIN_PATH=$SIGN_EVENT_BIN_MIPS
        EXPECTED_HASH=$(jq -r '.mips_binary_checksum' $CHECKSUMS_FILE)
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Call the install script to ensure the binary is available and up-to-date
$SCRIPT_DIR/install/install_signer.sh

# Function to generate event and JSON
generate_event_json() {
    # Extract keys and identifiers
    PUBLIC_KEY_HEX=$(jq -r '.npub_hex' "$JSON_FILE")
    PRIVATE_KEY_HEX=$(jq -r '.nsec_hex' "$JSON_FILE")

    # Ensure the binary is executable
    ensure_executable $BIN_PATH

    # Event data
    CONTENT=${1:-"Hello, Nostr!"}
    CREATED_AT=$(date +%s)
    SERIALIZED_EVENT="[0,\"$PUBLIC_KEY_HEX\",$CREATED_AT,1,[],\"$CONTENT\"]"
    
    # Generate the SHA-256 hash of the serialized event
    EVENT_HASH=$(echo -n "$SERIALIZED_EVENT" | sha256sum | awk '{print $1}')

    # Sign the hash using the private key
    SIGNATURE=$($BIN_PATH "$EVENT_HASH" "$PRIVATE_KEY_HEX")
    
    # Generate the event ID by hashing the serialized event
    EVENT_ID=$(echo -n "$SERIALIZED_EVENT" | sha256sum | awk '{print $1}')

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

    echo '["EVENT",' "$EVENT" ']' > $OUTPUT_FILE
    cat $OUTPUT_FILE
}

# Main execution flow
generate_event_json "$@"

