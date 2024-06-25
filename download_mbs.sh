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
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "cat $DATABASE_FILE" | grep -v "^#" | awk -F',' '{total_in+=$4; total_out+=$5} END {print total_in, total_out}'
}

# Function to get downloaded and uploaded data from ndsctl json
get_ndsctl_data() {
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "ndsctl json" | jq -c '.clients[] | select(.mac == "28:d2:44:64:f1:f7") | .downloaded, .uploaded' | awk '{down+=$1; up+=$2} END {print down, up}'
}

# Retrieve initial data usage from both wrtbwmon and ndsctl
setup_wrtbwmon
initial_wrtbwmon_data=$(get_wrtbwmon_data)
initial_wrtbwmon_downloaded=$(echo $initial_wrtbwmon_data | awk '{print $1}')
initial_wrtbwmon_uploaded=$(echo $initial_wrtbwmon_data | awk '{print $2}')

initial_ndsctl_data=$(get_ndsctl_data)
initial_ndsctl_downloaded=$(echo $initial_ndsctl_data | awk '{print $1}')
initial_ndsctl_uploaded=$(echo $initial_ndsctl_data | awk '{print $2}')

# Debug: Print initial ndsctl data
echo "Initial ndsctl data: downloaded = $initial_ndsctl_downloaded, uploaded = $initial_ndsctl_uploaded"

# Run iperf3 to generate network traffic for the specified amount of data
echo "Running iperf3 to download $NUM_MB MB"
iperf3 -c $IPERF_SERVER -n $NUM_BYTES

# Update wrtbwmon and retrieve final data usage
setup_wrtbwmon
final_wrtbwmon_data=$(get_wrtbwmon_data)
final_wrtbwmon_downloaded=$(echo $final_wrtbwmon_data | awk '{print $1}')
final_wrtbwmon_uploaded=$(echo $final_wrtbwmon_data | awk '{print $2}')

final_ndsctl_data=$(get_ndsctl_data)
final_ndsctl_downloaded=$(echo $final_ndsctl_data | awk '{print $1}')
final_ndsctl_uploaded=$(echo $final_ndsctl_data | awk '{print $2}')

# Calculate data consumed for both wrtbwmon and ndsctl
wrtbwmon_downloaded_consumed=$((final_wrtbwmon_downloaded - initial_wrtbwmon_downloaded))
wrtbwmon_uploaded_consumed=$((final_wrtbwmon_uploaded - initial_wrtbwmon_uploaded))

ndsctl_downloaded_consumed=$((final_ndsctl_downloaded - initial_ndsctl_downloaded))
ndsctl_uploaded_consumed=$((final_ndsctl_uploaded - initial_ndsctl_uploaded))

echo "Expected data download: $NUM_MB MB."
echo "Actual data downloaded (wrtbwmon): $((wrtbwmon_downloaded_consumed / 1024)) MB."
echo "Actual data uploaded (wrtbwmon): $((wrtbwmon_uploaded_consumed / 1024)) MB."
echo "Actual data downloaded (ndsctl): $((ndsctl_downloaded_consumed)) MB."
echo "Actual data uploaded (ndsctl): $((ndsctl_uploaded_consumed)) MB."

