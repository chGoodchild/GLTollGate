#!/bin/bash

# Define the router's IP address and password
ROUTER_IP="192.168.8.1"
ROUTER_USER="root"
ROUTER_PASSWORD="1"  # replace with your actual password
IPERF_SERVER="178.18.252.85"  # Replace with your iperf3 server IP

# Check if the number of MB to be downloaded is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_MB>"
  exit 1
fi

# Get the number of MB to be downloaded from the arguments
NUM_MB=$1
NUM_BYTES=$((NUM_MB * 1000000))  # Convert MB to Bytes

# Function to get downloaded and uploaded data from ndsctl json
get_data_usage() {
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "ndsctl json" | jq '.clients[] | .downloaded, .uploaded'
}

# Retrieve initial data usage from ndsctl
initial_data=$(get_data_usage)
initial_downloaded=$(echo $initial_data | awk '{print $1}')
initial_uploaded=$(echo $initial_data | awk '{print $2}')

# Run iperf3 to generate network traffic for the specified amount of data
echo "Running iperf3 to download $NUM_MB MB"
iperf3 -c $IPERF_SERVER -n $NUM_BYTES

# Retrieve final data usage from ndsctl
final_data=$(get_data_usage)
final_downloaded=$(echo $final_data | awk '{print $1}')
final_uploaded=$(echo $final_data | awk '{print $2}')

# Calculate data consumed
downloaded_consumed=$((final_downloaded - initial_downloaded))
uploaded_consumed=$((final_uploaded - initial_uploaded))

echo "Expected data download: $NUM_MB MB."
echo "Actual data downloaded (ndsctl): $((downloaded_consumed)) MB."
echo "Actual data uploaded (ndsctl): $((uploaded_consumed)) MB."

