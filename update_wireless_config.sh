#!/bin/sh

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <SSID> <PASSWORD>"
    exit 1
fi

# Assign arguments to variables
NEW_SSID=$1
NEW_PASSWORD=$2

# Path to the wireless config file
CONFIG_FILE="/etc/config/wireless"

# Use sed to replace the SSID and PASSWORD
sed -i "s/option ssid 'WIFI_SSID'/option ssid '$NEW_SSID'/" "$CONFIG_FILE"
sed -i "s/option key 'WIFI_PASSWORD'/option key '$NEW_PASSWORD'/" "$CONFIG_FILE"

# Check if the changes were made successfully
if [ $? -eq 0 ]; then
    echo "SSID and PASSWORD updated successfully."
    echo "New SSID: $NEW_SSID"
    echo "New PASSWORD: $NEW_PASSWORD"
else
    echo "Error: Failed to update the config file."
    exit 1
fi
