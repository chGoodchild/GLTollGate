#!/bin/sh -e
set -x

# API URLs
LNURL_DECODE_API_URL="https://demo.lnbits.com/api/v1/payments/decode"
LNURLP_URL="https://minibits.cash/.well-known/lnurlp/chandran"
API_KEY="5d0605a2fa0d4d6c8fe13fdec25720ca"
LNURLW="LNURL1DP68GURN8GHJ7ER9D4HJUMRWVF5HGUEWVDHK6TMHD96XSERJV9MJ7CTSDYHHVVF0D3H82UNV9A45SWZDWPFKYST8FEHNYET2DPJ4GKJ2W3AXZWAGEQ6"

# Step 1: Decode the LNURLw using the API
decode_response=$(curl -s -X POST $LNURL_DECODE_API_URL -d "{\"data\": \"$LNURLW\"}" -H "X-Api-Key: $API_KEY" -H "Content-type: application/json")
decoded_url=$(echo $decode_response | jq -r '.domain')

echo "Decoded URL: $decoded_url"

# Check if the decoded URL is valid
if [ -z "$decoded_url" ]; then
    echo "Error: Decoded URL is empty. Decoding failed."
    exit 1
fi

# Step 2: Visit the decoded URL to fetch withdrawal information
withdraw_info=$(curl -s "$decoded_url")
echo "Withdrawal Info: $withdraw_info"

# Extract callback URL and k1 value
callback_url=$(echo $withdraw_info | jq -r '.callback')
k1=$(echo $withdraw_info | jq -r '.k1')

# Check if callback URL and k1 value were extracted successfully
if [ -z "$callback_url" ] || [ -z "$k1" ]; then
    echo "Error: Failed to extract callback URL or k1 value."
    exit 1
fi

echo "Callback URL: $callback_url"
echo "k1: $k1"

# Step 3: Get the dynamic BOLT11 invoice using the LNURLp
get_bolt11_invoice() {
    echo "Getting BOLT11 invoice..."
    lnurlp_response=$(curl -s "$LNURLP_URL")
    max_sendable=$(echo $lnurlp_response | jq -r '.maxSendable')
    
    echo "Max sendable amount: $max_sendable msats"
    
    # Request 1 satoshi (1000 msats)
    amount=1000
    lnurl_payment_request=$(curl -s "$LNURLP_URL?amount=$amount")
    bolt11_invoice=$(echo $lnurl_payment_request | jq -r '.pr')
    
    if [ -z "$bolt11_invoice" ]; then
        echo "Error: Failed to retrieve BOLT11 invoice."
        exit 1
    fi
    
    echo "BOLT11 Invoice: $bolt11_invoice"
    echo $bolt11_invoice
}

# Retrieve the BOLT11 invoice dynamically
BOLT11_INVOICE=$(get_bolt11_invoice | tail -n 1)

# Step 4: Submit the BOLT11 invoice
full_callback_url="${callback_url}?k1=${k1}&pr=${BOLT11_INVOICE}"
echo "Full Callback URL: $full_callback_url"

response=$(curl -s "$full_callback_url")

# Output the response
echo "Response: $response"

# Check if the response was successful
if [ -z "$response" ]; then
    echo "Error: Failed to get a response from the callback URL."
    exit 1
fi
