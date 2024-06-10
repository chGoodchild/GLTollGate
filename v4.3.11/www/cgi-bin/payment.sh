#!/bin/sh

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
      echo "Connection rejected: Invalid e-cash" >> /tmp/arguments_log.md
      exit 1
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
