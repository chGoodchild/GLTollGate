#!/bin/sh -e
set -x

# Base URLs of the services
MINT_URL="https://mint.minibits.cash/Bitcoin"
LNURL="https://minibits.cash/.well-known/lnurlp/chandran"

# Token can be passed as an argument to the script
TOKEN="$1"

# Function to decode the token and calculate total amount
decode_token() {
    echo "Decoding token..."
    # TOKEN="cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHBzOi8vbWludC5taW5pYml0cy5jYXNoL0JpdGNvaW4iLCJwcm9vZnMiOlt7ImlkIjoiOW1sZmQ1dkN6Z0dsIiwiYW1vdW50Ijo0LCJzZWNyZXQiOiJkY2VjYjNiYWQwYmU1ODlhNGE0NzRmZDY5NWE3ZWRmZDFlM2QxYWIwNDIyNjQzZTgzMGFmNmY2NmFmY2RiMTAwIiwiQyI6IjAzYTFmNTAxYmZlNWU4MWRiZWQ3MmM1OTFlZDc0MjgxOWRlNDhlYzhmNzllYmQ4ZWU4OTUzYjMzYmYwNWYxMWJiOSJ9XX1dLCJ1bml0Ijoic2F0IiwibWVtbyI6IlNlbnQgZnJvbSBNaW5pYml0cyJ9"
    
    echo $TOKEN
    
    # Remove the 'cashuA' prefix before decoding
    # BASE64_TOKEN=$(echo "${TOKEN:6}")
    BASE64_TOKEN=$(echo "$TOKEN" | cut -b 7-)
    
    echo "Base64 Token: $BASE64_TOKEN"

    # Clean up the base64 token to remove any invalid characters
    CLEANED_BASE64_TOKEN=$(echo "$BASE64_TOKEN" | tr -d '\n\r')
    echo "Cleaned Base64 Token: $CLEANED_BASE64_TOKEN"

    # Ensure proper padding
    PADDING=$((${#CLEANED_BASE64_TOKEN} % 4))
    if [ $PADDING -ne 0 ]; then
        CLEANED_BASE64_TOKEN="${CLEANED_BASE64_TOKEN}$(printf '%0.s=' $(seq 1 $((4 - PADDING))))"
    fi
    echo "Padded Base64 Token: $CLEANED_BASE64_TOKEN"

    # Decode base64, handle any errors
    DECODED_TOKEN=$(echo "$CLEANED_BASE64_TOKEN" | base64 --decode 2>/dev/null)
    if [ -z "$DECODED_TOKEN" ]; then
        echo "Error decoding token or token is empty."
        exit 1
    fi

    # Print the decoded JSON
    echo "Decoded JSON: $DECODED_TOKEN"

    # Validate JSON format
    if ! echo "$DECODED_TOKEN" | jq . > /dev/null 2>&1; then
        echo "Decoded token is not valid JSON."
        exit 1
    fi

    # Parse the JSON to extract necessary values
    TOTAL_AMOUNT=0
    PROOFS=$(echo "$DECODED_TOKEN" | jq -c '.token[0].proofs[]')
    PROOFS_JSON="["
    FIRST_PROOF=true
    for PROOF in $PROOFS; do
        AMOUNT=$(echo "$PROOF" | jq -r '.amount')
        TOTAL_AMOUNT=$((TOTAL_AMOUNT + AMOUNT))
        if [ "$FIRST_PROOF" = true ]; then
            PROOFS_JSON="$PROOFS_JSON$PROOF"
            FIRST_PROOF=false
        else
            PROOFS_JSON="$PROOFS_JSON,$PROOF"
        fi
    done
    PROOFS_JSON="$PROOFS_JSON]"

    # Print total amount for debugging purposes
    echo "Proofs JSON: $PROOFS_JSON"
    echo "Total amount to transfer: $TOTAL_AMOUNT sats"

    # Extract other necessary details from the first proof
    FIRST_PROOF=$(echo "$PROOFS" | head -n 1)
    PROOF_SECRET=$(echo "$FIRST_PROOF" | jq -r '.secret')
    PROOF_ID=$(echo "$FIRST_PROOF" | jq -r '.id')
    PROOF_C=$(echo "$FIRST_PROOF" | jq -r '.C')

    # Check if parsing was successful
    if [ -z "$PROOF_SECRET" ] || [ -z "$PROOF_ID" ] || [ -z "$PROOF_C" ]; then
        echo "Error parsing decoded token JSON"
        exit 1
    fi

}

# Function to get mint keys
get_mint_keys() {
    echo "Getting mint keys..."
    RESPONSE=$(curl -s "$MINT_URL/keys" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=1' \
        -H 'TE: trailers')
    echo "Mint keys response: $RESPONSE"
}

# Function to check the token and validate the proof values
check_token() {
    echo "Checking token..."
    RESPONSE=$(curl -s -X POST "$MINT_URL/check" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Content-Type: application/json' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=4' \
        -H 'TE: trailers' \
        --data-raw "{\"proofs\":[{\"secret\":\"$PROOF_SECRET\"}]}")
    
    if echo "$RESPONSE" | jq -e . >/dev/null 2>&1; then
        echo "Token check response: $RESPONSE"
        echo "Extracted proof secret: $PROOF_SECRET"
        echo "Extracted proof id: $PROOF_ID"
        echo "Extracted proof C: $PROOF_C"
    else
        echo "Error in token check response: $RESPONSE"
        exit 1
    fi
}

# Function to get lnurl payment request details and extract the amount
get_lnurl_details() {
    echo "Getting lnurl details..."
    LNURL_DETAILS=$(curl -s "$LNURL" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=1')
    if echo "$LNURL_DETAILS" | jq -e . >/dev/null 2>&1; then
        LNURL_AMOUNT=$(echo $LNURL_DETAILS | jq -r '.maxSendable')
        echo "LNURL details: $LNURL_DETAILS"
        echo "Extracted lnurl amount: $LNURL_AMOUNT"
    else
        echo "Error in lnurl details response: $LNURL_DETAILS"
        exit 1
    fi
}

# Function to get the payment request for a specific amount
get_payment_request() {
    echo "Getting payment request for amount $TOTAL_AMOUNT..."
    PAYMENT_REQUEST=$(curl -s "$LNURL?amount=$((TOTAL_AMOUNT * 1000))" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=4' \
        -H 'TE: trailers')
    PAYMENT_REQUEST=$(echo $PAYMENT_REQUEST | jq -r '.pr')
    echo "Payment request response: $PAYMENT_REQUEST"
}

# Function to check fees for the payment request
check_fees() {
    echo "Checking fees for the payment request..."
    RESPONSE=$(curl -s -X POST "$MINT_URL/checkfees" \
        -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Accept-Language: en-US,en;q=0.5' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://redeem.cashu.me/' \
        -H 'Content-Type: application/json' \
        -H 'Origin: https://redeem.cashu.me' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: empty' \
        -H 'Sec-Fetch-Mode: cors' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-GPC: 1' \
        -H 'Priority: u=4' \
        -H 'TE: trailers' \
        --data-raw "{\"pr\":\"$PAYMENT_REQUEST\"}")
    echo "Check fees response: $RESPONSE"
}

# Function to redeem the token
redeem_token() {
  echo "Redeeming token..."
  RESPONSE=$(curl -s -X POST "$MINT_URL/melt" \
    -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:126.0) Gecko/20100101 Firefox/126.0' \
    -H 'Accept: application/json, text/plain, */*' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Accept-Encoding: gzip, deflate, br, zstd' \
    -H 'Referer: https://redeem.cashu.me/' \
    -H 'Content-Type: application/json' \
    -H 'Origin: https://redeem.cashu.me' \
    -H 'Connection: keep-alive' \
    -H 'Sec-Fetch-Dest: empty' \
    -H 'Sec-Fetch-Mode: cors' \
    -H 'Sec-Fetch-Site: cross-site' \
    -H 'Sec-GPC: 1' \
    -H 'Priority: u=4' \
    -H 'TE: trailers' \
    --data-raw "{\"pr\":\"$PAYMENT_REQUEST\",\"proofs\":$PROOFS_JSON,\"outputs\":[]}")
  echo "Redeem response: $RESPONSE"
}

# Check if token is provided
if [ -z "$TOKEN" ]; then
  echo "Usage: $0 <token>"
  exit 1
fi


echo "Curl request - ECASH: $ECASH" >> /tmp/arguments_log.md

# Decode the token
decode_token

# Execute the sequence of requests
get_mint_keys
check_token
get_lnurl_details
get_payment_request
check_fees
redeem_token

