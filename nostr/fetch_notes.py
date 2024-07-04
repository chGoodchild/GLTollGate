import asyncio
from nostr.relay import Relay
from nostr.relay import RelayPolicy  # Corrected import path if it exists within relay.py
from nostr.message_pool import MessagePool
from nostr.subscription import Subscription

async def fetch_notes():
    # Define the relay URL and your public key
    relay_url = "wss://relay.nostr.bg"
    public_key = "npub1vfl7v8fgwxnv88u6n5t3pwsmzqg7xajclmtlfqncpaf2crefqr9qu2kruy"
    
    # Setup the relay policy and message pool
    policy = RelayPolicy(should_read=True, should_write=True)
    message_pool = MessagePool()

    # Create a relay instance
    relay = Relay(relay_url, policy, message_pool)

    # Define the filters for the events based on your public key
    subscription = Subscription("1")  # Assuming subscription ID is required and can be any identifier
    subscription.filters = {"#p": [public_key]}  # Adjusted to match the expected dictionary structure

    # Define a callback function to handle received events
    def handle_event(event):
        print('Received Event:', event)

    # Register the callback with the relay (adjust based on actual implementation availability)
    relay.add_subscription("1", subscription.filters)  # Adjusted to pass filters correctly

    # Connect to the relay and start listening for events
    await relay.connect()
    await relay.subscribe(subscription)

    # Keep the connection open
    await asyncio.Future()  # This will block forever unless cancelled

if __name__ == '__main__':
    asyncio.run(fetch_notes())
