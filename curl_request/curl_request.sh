#!/bin/bash

# Base URLs of the services
MINT_URL="https://mint.minibits.cash/Bitcoin"
LNURL="https://minibits.cash/.well-known/lnurlp/chandran"

# Token can be passed as an argument to the script
TOKEN="$1"

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

# Function to check the token and extract the proof secret
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
  PROOF_SECRET=$(echo $RESPONSE | jq -r '.proofs[0].secret')
  echo "Token check response: $RESPONSE"
  echo "Extracted proof secret: $PROOF_SECRET"
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
  LNURL_AMOUNT=$(echo $LNURL_DETAILS | jq -r '.maxSendable')
  echo "LNURL details: $LNURL_DETAILS"
  echo "Extracted lnurl amount: $LNURL_AMOUNT"
}

# Function to get the payment request for a specific amount
get_payment_request() {
  echo "Getting payment request for amount $LNURL_AMOUNT..."
  PAYMENT_REQUEST=$(curl -s "$LNURL?amount=$LNURL_AMOUNT" \
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
    --data-raw "{\"pr\":\"$PAYMENT_REQUEST\",\"proofs\":[{\"id\":\"9mlfd5vCzgGl\",\"amount\":4,\"secret\":\"$PROOF_SECRET\",\"C\":\"031717478db4665f8eebffb51cc759a7246a1964b2d01c017dad49c9d291f55d83\"}],\"outputs\":[]}")
  echo "Redeem response: $RESPONSE"
}

# Check if token is provided
if [[ -z "$TOKEN" ]]; then
  echo "Usage: $0 <token>"
  exit 1
fi

# Execute the sequence of requests
get_mint_keys
check_token
get_lnurl_details
get_payment_request
check_fees
redeem_token
