import json
from datetime import datetime
from nostr.key import PrivateKey
from nostr.event import Event

# Load the keys from the JSON file
json_file = "nostr_keys.json"
with open(json_file, 'r') as f:
    keys = json.load(f)

# Ensure the private key is correctly loaded as bech32 format
private_key_nsec = keys['nsec']  # Assuming this is the bech32 format key
public_key_hex = keys['npub_hex']

# Create a PrivateKey object from the bech32 encoded key
private_key = PrivateKey.from_nsec(private_key_nsec)

# Event data
content = "Hello, Nostr!"
created_at = int(datetime.now().timestamp())

# Create the event
event = Event(
    public_key=private_key.public_key.hex(),
    content=content,
    created_at=created_at,
    kind=1,
    tags=[]
)

# Sign the event
private_key.sign_event(event)

# Print the final event
final_event = event.to_message()
print(final_event)

# Save to send.json
with open('send.json', 'w') as f:
    f.write(final_event)
