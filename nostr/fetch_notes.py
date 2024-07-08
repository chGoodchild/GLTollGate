import asyncio
import json
import time
import uuid
import nest_asyncio
from pynostr.relay import Relay
from pynostr.relay_manager import RelayManager
from pynostr.filters import Filters, FiltersList
from pynostr.message_type import ClientMessageType

nest_asyncio.apply()

async def subscribe_to_relay(relay_url, subscription_request):
    relay = Relay(
        relay_url,
        subscription_request.message_pool,
        subscription_request.io_loop,
        subscription_request.policy,
        timeout=2
    )

    await relay.connect()
    print(f"Connected to relay {relay_url}")

    def handle_event(event):
        print(f"Received Event: {event}")
        content = event.event.content if event.event else None
        if content:
            print(f"Note Content: {content}")

    subscription_request.message_pool.on_event.append(handle_event)
    print("Added event handler")

    await relay.subscribe(subscription_request)
    print(f"Subscribed to relay {relay_url}")

    # Keep the connection open
    await asyncio.Future()  # This will block forever unless cancelled

async def main():
    relays = [
        "wss://orangesync.tech"
    ]
    public_key = "24b37f5ec0822b014c6ebb425641ac83529d47bce44d70272b3a95cf93f64cc1"
    subscription_id = uuid.uuid1().hex

    current_timestamp = int(time.time())
    since_timestamp = current_timestamp - 3600

    filter_dict = {
        "authors": [public_key],
        "since": since_timestamp
    }

    filters = Filters(**filter_dict)
    filters_list = FiltersList([filters])
    
    relay_manager = RelayManager(timeout=2)
    for relay_url in relays:
        relay_manager.add_relay(relay_url)
    
    relay_manager.add_subscription_on_all_relays(subscription_id, filters_list)
    print(f"Subscription request sent with ID {subscription_id}")

    relay_manager.run_sync()
    print("Relay manager running")

    while relay_manager.message_pool.has_events():
        event_msg = relay_manager.message_pool.get_event()
        print(f"Event Content: {event_msg.event.content}")

if __name__ == '__main__':
    asyncio.run(main())

