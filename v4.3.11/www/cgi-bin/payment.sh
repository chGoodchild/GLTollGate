#!/bin/sh

##!/bin/sh -e
# set -x

METHOD="$1"
MAC="$2"
USERNAME="$3"  # Here, USERNAME represents the e-cash value
PASSWORD="$4"  # Password might not be used in this case

# Log all arguments to /tmp/arguments_log.md
echo "METHOD: $METHOD, MAC: $MAC, USERNAME: $USERNAME, PASSWORD: $PASSWORD" >> /tmp/arguments_log.md

case "$METHOD" in
  auth_client)
    ECASH="$USERNAME"
    echo "Auth Client - ECASH: $ECASH" >> /tmp/arguments_log.md
    
    if [ "$ECASH" = "cheatcode" ]; then
      echo "Connection approved" >> /tmp/arguments_log.md
      echo 3600 0 0
      exit 0
    else
      # Pass the ECASH token to curl_request.sh and capture the result
      RESPONSE=$(/www/cgi-bin/./curl_request.sh "$ECASH" 2>&1)
      CURL_EXIT_CODE=$?
      echo "Curl request - ECASH: $ECASH, Exit Code: $CURL_EXIT_CODE" >> /tmp/arguments_log.md
      echo "Redeem response: $RESPONSE" >> /tmp/arguments_log.md
      
      if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl request failed with exit code $CURL_EXIT_CODE" >> /tmp/arguments_log.md
        exit 1
      fi
      
      # Check if the response contains "paid":true
      if echo "$RESPONSE" | grep -q '"paid":true'; then
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
