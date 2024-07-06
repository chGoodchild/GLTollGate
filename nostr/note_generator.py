import json
import hashlib
from ecdsa import SigningKey, SECP256k1
from datetime import datetime

# Load the keys from the JSON file
json_file = "nostr_keys.json"
with open(json_file, 'r') as f:
    keys = json.load(f)

public_key_hex = keys['npub_hex']
private_key_hex = keys['nsec_hex']
private_key_id = keys['nsec']
pem_file = f"{private_key_id}.pem"

# Ensure the PEM file exists
try:
    with open(pem_file, 'r') as f:
        pem_data = f.read()
except FileNotFoundError:
    print(f"PEM file {pem_file} does not exist.")
    exit(1)

# Load the private key from the PEM file
private_key = SigningKey.from_pem(pem_data)

# Event data
content = "Hello, Nostr!"
created_at = int(datetime.now().timestamp())

# Create the event JSON without id and sig
event = {
    "id": "",
    "pubkey": public_key_hex,
    "created_at": 1720275679,
    "kind": 1,
    "tags": [],
    "content": "Hello, Nostr!",
    "sig": ""
}

# Serialize the event data
serialized_event = json.dumps([0, public_key_hex, created_at, 1, [], content], separators=(',', ':'))

# Hash the serialized event
event_hash = hashlib.sha256(serialized_event.encode()).digest()

# Sign the hashed event
signature = private_key.sign(event_hash)
signature_hex = signature.hex()

# Compute the event ID
event_id = hashlib.sha256(json.dumps(event, separators=(',', ':')).encode()).hexdigest()

# Update the event with the ID and signature
event["id"] = event_id
event["sig"] = signature_hex

# Print the final event
final_event = json.dumps(["EVENT", event], indent=2)
print(final_event)

# Save to send.json
with open('send.json', 'w') as f:
    f.write(final_event)

