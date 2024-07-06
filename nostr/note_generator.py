import json
import hashlib
from datetime import datetime
from ecdsa import SigningKey, SECP256k1
from ecdsa.util import sigencode_string

# Function to serialize the event
def serialize_event(public_key, created_at, kind, tags, content):
    data = [0, public_key, created_at, kind, tags, content]
    data_str = json.dumps(data, separators=(',', ':'), ensure_ascii=False)
    return data_str.encode()

# Function to compute the event ID
def compute_event_id(public_key, created_at, kind, tags, content):
    return hashlib.sha256(serialize_event(public_key, created_at, kind, tags, content)).hexdigest()

# Load the keys from the JSON file
json_file = "nostr_keys.json"
with open(json_file, 'r') as f:
    keys = json.load(f)

# Extract keys and identifiers
private_key_hex = keys['nsec_hex']
public_key_hex = keys['npub_hex']

# Convert the hex private key to bytes
private_key_bytes = bytes.fromhex(private_key_hex)

# Create the private key object
private_key = SigningKey.from_string(private_key_bytes, curve=SECP256k1)

# Event data
content = "Hello, Nostr!"
created_at = int(datetime.now().timestamp())

# Create the event data (excluding 'id' and 'sig')
event = {
    "pubkey": public_key_hex,
    "created_at": created_at,
    "kind": 1,
    "tags": [],
    "content": content,
}

# Compute the event ID by hashing the serialized event data
event_id = compute_event_id(public_key_hex, created_at, 1, [], content)
event['id'] = event_id

# Serialize the event data for signing
serialized_event = serialize_event(public_key_hex, created_at, 1, [], content)

# Compute the event hash
event_hash = hashlib.sha256(serialized_event).digest()

# Sign the serialized event data
signature = private_key.sign_deterministic(event_hash, hashfunc=hashlib.sha256, sigencode=sigencode_string)

# Convert the signature to hex format
event['sig'] = signature.hex()

# Print the final event
final_event = ["EVENT", event]
final_event_json = json.dumps(final_event, indent=2)
print(final_event_json)

# Save to send.json
with open('send.json', 'w') as f:
    f.write(final_event_json)

