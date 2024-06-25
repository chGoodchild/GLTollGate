#!/bin/bash

# Define the router's IP address and password
ROUTER_IP="192.168.8.1"
ROUTER_USER="root"
ROUTER_PASSWORD="1"  # replace with your actual password
IPERF_SERVER="178.18.252.85"  # Replace with your iperf3 server IP
DATABASE_FILE="/tmp/usage.db"

# Check if the number of MB to be downloaded is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_MB>"
  exit 1
fi

# Get the number of MB to be downloaded from the arguments
NUM_MB=$1
NUM_BYTES=$((NUM_MB * 1000000))  # Convert MB to Bytes

# Function to setup and update wrtbwmon
setup_wrtbwmon() {
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "wrtbwmon setup $DATABASE_FILE"
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "wrtbwmon update $DATABASE_FILE"
}

# Function to get data usage from wrtbwmon
get_wrtbwmon_data() {
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "cat $DATABASE_FILE" | grep "28:d2:44:64:f1:f7" | awk -F',' '{print $4, $5}'
}

# Setup wrtbwmon and retrieve initial data usage
setup_wrtbwmon
initial_data=$(get_wrtbwmon_data)
initial_downloaded=$(echo $initial_data | awk '{print $1}')
initial_uploaded=$(echo $initial_data | awk '{print $2}')

# Run iperf3 to generate network traffic for the specified amount of data
echo "Running iperf3 to download $NUM_MB MB"
iperf3 -c $IPERF_SERVER -n $NUM_BYTES

# Update wrtbwmon and retrieve final data usage
setup_wrtbwmon
final_data=$(get_wrtbwmon_data)
final_downloaded=$(echo $final_data | awk '{print $1}')
final_uploaded=$(echo $final_data | awk '{print $2}')

# Calculate data consumed
downloaded_consumed=$((final_downloaded - initial_downloaded))
uploaded_consumed=$((final_uploaded - initial_uploaded))

echo "Expected data download: $NUM_MB MB."
echo "Actual data downloaded (wrtbwmon): $((downloaded_consumed / 1024)) MB."
echo "Actual data uploaded (wrtbwmon): $((uploaded_consumed / 1024)) MB."

