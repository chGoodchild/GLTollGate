import asyncio
from nostr.client import Client

async def fetch_notes(npub):
    client = Client("wss://relay.nostr.bg")
    events = await client.get_events({'#p': [npub]})
    for event in events:
        print(event)

if __name__ == "__main__":
    npub = 'npub1yjeh7hkqsg4sznrwhdp9vsdvsdff63auu3xhqfet822ulylkfnqsgcpy8t'
    asyncio.run(fetch_notes(npub))
