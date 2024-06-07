#!/bin/sh

METHOD="$1"
MAC="$2"
ARG3="$3"
ARG4="$4"
ARG5="$5"
ARG6="$6"

# Log all arguments to /tmp/arguments_log.md
echo "METHOD: $METHOD, MAC: $MAC, ARG3: $ARG3, ARG4: $ARG4, ARG5: $ARG5, ARG6: $ARG6" >> /tmp/arguments_log.md

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
    # client_auth: Client authenticated via this script.
    # client_deauth: Client deauthenticated by the client via splash page.
    # idle_deauth: Client was deauthenticated because of inactivity.
    # timeout_deauth: Client was deauthenticated because the session timed out.
    # ndsctl_auth: Client was authenticated by the ndsctl tool.
    # ndsctl_deauth: Client was deauthenticated by the ndsctl tool.
    # shutdown_deauth: Client was deauthenticated by Nodogsplash terminating.
    echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES, SESSION_START: $SESSION_START, SESSION_END: $SESSION_END" >> /tmp/arguments_log.md
    ;;
esac

