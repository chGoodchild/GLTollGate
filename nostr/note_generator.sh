#!/bin/sh

# Configuration
PRIVATE_KEY="your_private_key_here"  # Replace with your actual private key
PUBLIC_KEY="your_public_key_here"    # Replace with your actual public key
RELAYS="wss://relay1.example.com wss://relay2.example.com"  # List of relays
CONTENT="Hello, Nostr!"              # Content of the note

# Create Event
CREATED_AT=$(date +%s)
EVENT=$(printf '{"id":"","pubkey":"%s","created_at":%s,"kind":1,"tags":[],"content":"%s","sig":""}' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Serialize Event
SERIALIZED_EVENT=$(printf '[0,"%s",%s,1,[],"%s"]' "$PUBLIC_KEY" "$CREATED_AT" "$CONTENT")

# Create Event ID
EVENT_ID=$(echo -n $SERIALIZED_EVENT | openssl dgst -sha256 | awk '{print $2}')

# Sign Event
SIGNATURE=$(echo -n $EVENT_ID | openssl dgst -sha256 -sign <(echo -n $PRIVATE_KEY) | openssl dgst -sha256 | awk '{print $2}')

# Update Event with ID and Signature
EVENT=$(echo $EVENT | sed "s/\"id\":\"\"/\"id\":\"$EVENT_ID\"/" | sed "s/\"sig\":\"\"/\"sig\":\"$SIGNATURE\"/")

# Publish Event to Relays
for RELAY in $RELAYS; do
    echo "Publishing to $RELAY"
    echo '[ "EVENT", '"$EVENT"' ]' | websocat "$RELAY"
done

