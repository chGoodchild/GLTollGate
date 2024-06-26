#!/bin/sh -e
set -x

LOGFILE="/var/log/nodogsplash_data_purchases.json"
USAGE_LOGFILE="/var/log/nodogsplash_data_usage.json"

# Function to update purchase log with token if missing
update_purchase_log_with_token() {
  client_usage=$(ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.token)"')
  echo "Updating Purchase Log with Tokens"  # Debugging line

  echo "$client_usage" | while read -r mac token; do
    jq --arg mac "$mac" --arg token "$token" '
    map(if .mac == $mac and (.token | length) == 0 then .token = $token else . end)
    ' "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"
  done
}

# Main
update_purchase_log_with_token
