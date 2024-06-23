#!/bin/sh

##!/bin/sh -e
# set -x

LOGFILE="/var/log/nodogsplash_data_purchases.json"
USAGE_LOGFILE="/var/log/nodogsplash_data_usage.json"

METHOD="$1"
MAC="$2"
USERNAME="$3"  # Here, USERNAME represents either the e-cash value or LNURLW
PASSWORD="$4"  # Password might not be used in this case

# Log all arguments to /tmp/arguments_log.md
echo "METHOD: $METHOD, MAC: $MAC, USERNAME: $USERNAME, PASSWORD: $PASSWORD" >> /tmp/arguments_log.md

# Ensure the usage log file exists
if [ ! -f "$USAGE_LOGFILE" ]; then
  echo "{}" > "$USAGE_LOGFILE"
fi

# Pricing model
MSAT_PER_KB=3

case "$METHOD" in
  auth_client)
    ECASH="$USERNAME"
    echo "Auth Client - ECASH: $ECASH" >> /tmp/arguments_log.md

    if echo "$ECASH" | grep -q "^LNURL"; then
      # Handle LNURLW
      RESPONSE=$(/www/cgi-bin/redeem_lnurlw.sh "$ECASH" 2>&1)
      CURL_EXIT_CODE=$?
      echo "Curl request - LNURLW: $ECASH, Exit Code: $CURL_EXIT_CODE" >> /tmp/arguments_log.md
      echo "Redeem response: $RESPONSE" >> /tmp/arguments_log.md

      if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl request failed with exit code $CURL_EXIT_CODE" >> /tmp/arguments_log.md
        exit 1
      fi

      # Check if the response contains "status":"OK"
      if echo "$RESPONSE" | jq -e '.status == "OK"' > /dev/null; then
        echo "Received response: $RESPONSE" >> /tmp/arguments_log.md
        PAID_AMOUNT=$(echo "$RESPONSE" | jq -r '.paid_amount')
        TOTAL_AMOUNT_MSAT=$((PAID_AMOUNT * 1000))
        echo "Amount paid: $PAID_AMOUNT" >> /tmp/arguments_log.md
        echo "Total amount msat: $TOTAL_AMOUNT_MSAT" >> /tmp/arguments_log.md
        DATA_AMOUNT=$(awk "BEGIN {print $TOTAL_AMOUNT_MSAT / $MSAT_PER_KB}")
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        
        # Read existing JSON, append new entry, and write back
        if [ -f "$LOGFILE" ]; then
          jq --arg timestamp "$TIMESTAMP" --arg mac "$MAC" --arg data_amount "$DATA_AMOUNT" \
            '. += [{"timestamp": $timestamp, "mac": $mac, "data_amount": $data_amount}]' \
            "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
        else
          echo "[{\"timestamp\": \"$TIMESTAMP\", \"mac\": \"$MAC\", \"data_amount\": \"$DATA_AMOUNT\"}]" > "$LOGFILE"
        fi
        
        echo "Connection approved: LNURLW redeemed successfully" >> /tmp/arguments_log.md
        echo 3600 0 0
        exit 0
      else
        echo "Connection rejected: LNURLW redemption failed" >> /tmp/arguments_log.md
        exit 1
      fi
    else
      # Handle e-cash
      RESPONSE=$(/www/cgi-bin/./curl_request.sh "$ECASH" 2>&1)
      CURL_EXIT_CODE=$?
      echo "Curl request - ECASH: $ECASH, Exit Code: $CURL_EXIT_CODE" >> /tmp/arguments_log.md
      echo "Redeem response: $RESPONSE" >> /tmp/arguments_log.md

      if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl request failed with exit code $CURL_EXIT_CODE" >> /tmp/arguments_log.md
        exit 1
      fi

      # Check if the response contains "paid":true
      if echo "$RESPONSE" | jq -e '.paid == true' > /dev/null; then
        echo "Received response: $RESPONSE" >> /tmp/arguments_log.md
        PAID_AMOUNT=$(echo "$RESPONSE" | jq -r '.total_amount | tonumber')
        TOTAL_AMOUNT_MSAT=$((PAID_AMOUNT * 1000))
        echo "Amount paid: $PAID_AMOUNT" >> /tmp/arguments_log.md
        echo "Total amount msat: $TOTAL_AMOUNT_MSAT" >> /tmp/arguments_log.md
        DATA_AMOUNT=$(awk "BEGIN {print $TOTAL_AMOUNT_MSAT / $MSAT_PER_KB}")
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        
        # Read existing JSON, append new entry, and write back
        if [ -f "$LOGFILE" ]; then
          jq --arg timestamp "$TIMESTAMP" --arg mac "$MAC" --arg data_amount "$DATA_AMOUNT" \
            '. += [{"timestamp": $timestamp, "mac": $mac, "data_amount": $data_amount}]' \
            "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
        else
          echo "[{\"timestamp\": \"$TIMESTAMP\", \"mac\": \"$MAC\", \"data_amount\": \"$DATA_AMOUNT\"}]" > "$LOGFILE"
        fi
        
        echo "Connection approved: Token redeemed successfully" >> /tmp/arguments_log.md
        echo 3600 0 0
        exit 0
      else
        echo "Connection rejected: Token redemption failed" >> /tmp/arguments_log.md
        exit 1
      fi
    fi
    ;;
  client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
    INGOING_BYTES="$3"
    OUTGOING_BYTES="$4"
    # SESSION_START="$5"
    # SESSION_END="$6"
    # Log the details of client actions
    # echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES, SESSION_START: $SESSION_START, SESSION_END: $SESSION_END" >> /tmp/arguments_log.md
    echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES" >> /tmp/arguments_log.md
    ;;
esac

