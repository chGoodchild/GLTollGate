#!/bin/bash

# Base URL of the Cashu Redeem service
BASE_URL="https://redeem.cashu.me"

# Token and lnurl can be passed as arguments to the script
TOKEN="$1"
LNURL="$2"

# Function to check the token
check_token() {
  echo "Checking token..."
  RESPONSE=$(curl -s -X POST "$BASE_URL/check-token" -H "Content-Type: application/json" -d "{\"token\":\"$TOKEN\"}")
  echo "Token check response: $RESPONSE"
}

# Function to get lnurl payment request details
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
  echo "LNURL details: $LNURL_DETAILS"
}

# Function to redeem the token
redeem_token() {
  echo "Redeeming token..."
  RESPONSE=$(curl -s -X POST "$BASE_URL/redeem" -H "Content-Type: application/json" -d "{\"token\":\"$TOKEN\", \"lnurl\":\"$LNURL\"}")
  echo "Redeem response: $RESPONSE"
}

# Check if both token and lnurl are provided
if [[ -z "$TOKEN" || -z "$LNURL" ]]; then
  echo "Usage: $0 <token> <lnurl>"
  exit 1
fi

# Check the token
check_token

# Get lnurl details
get_lnurl_details

# Redeem the token
redeem_token
