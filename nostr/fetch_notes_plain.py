import asyncio
import websockets
import json

async def fetch_notes():
    uri = "wss://relay.nostr.bg"
    async with websockets.connect(uri) as websocket:
        # Ensure the payload matches the Nostr protocol requirements
        payload = {
            "req": "EVENTS",
            "filters": [{"#p": ["npub1yjeh7hkqsg4sznrwhdp9vsdvsdff63auu3xhqfet822ulylkfnqsgcpy8t"]}]
        }
        await websocket.send(json.dumps(payload))
        
        # Listen for a response until the connection is closed
        try:
            response = await websocket.recv()
            print(response)
        except websockets.exceptions.ConnectionClosed:
            print("Connection closed by the server")

asyncio.run(fetch_notes())
