#!/bin/sh

METHOD="$1"
MAC="$2"

INGOING_BYTES="$3"
OUTGOING_BYTES="$4"
SESSION_START="$5"
SESSION_END="$6"
echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES, SESSION_START: $SESSION_START, SESSION_END: $SESSION_END" >> /tmp/arguments_log.md

case "$METHOD" in
  auth_client)
    ECASH="$3"
    echo "Auth Client - ECASH: $ECASH" >> /tmp/arguments_log.md
    echo 3600 0 0
    exit 0
    ;;
  client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
    INGOING_BYTES="$3"
    OUTGOING_BYTES="$4"
    SESSION_START="$5"
    SESSION_END="$6"
    # Log the details of client actions
    echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES, SESSION_START: $SESSION_START, SESSION_END: $SESSION_END" >> /tmp/arguments_log.md
    ;;
esac

