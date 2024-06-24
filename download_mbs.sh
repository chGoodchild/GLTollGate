#!/bin/bash

# Define the router's IP address and password
ROUTER_IP="192.168.8.1"
ROUTER_USER="root"
ROUTER_PASSWORD="1"  # replace with your actual password

# Check if the number of MB to be downloaded is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_MB>"
  exit 1
fi

# Get the number of MB to be downloaded from the first argument
NUM_MB=$1

# Function to get downloaded and uploaded data from ndsctl json
get_data_usage() {
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "ndsctl json" | jq '.clients[] | .downloaded, .uploaded'
}

# Retrieve initial data usage
initial_data=$(get_data_usage)
initial_downloaded=$(echo $initial_data | awk '{print $1}')
initial_uploaded=$(echo $initial_data | awk '{print $2}')

# Calculate the number of 25 MB and 1 MB files needed
NUM_25MB=$((NUM_MB / 25))
NUM_1MB=$((NUM_MB % 25))

# Download 25 MB files
for ((i=1; i<=NUM_25MB; i++))
do
  echo "Downloading 25MB file $i of $NUM_25MB..."
  wget "https://github.com/chGoodchild/GLTollGate/raw/main/25MB_file?$(date +%s)" -O /dev/null
done

# Download 1 MB files
for ((i=1; i<=NUM_1MB; i++))
do
  echo "Downloading 1MB file $i of $NUM_1MB..."
  wget "https://github.com/chGoodchild/GLTollGate/raw/main/1MB_test_file?$(date +%s)" -O /dev/null
done

# Retrieve final data usage
final_data=$(get_data_usage)
final_downloaded=$(echo $final_data | awk '{print $1}')
final_uploaded=$(echo $final_data | awk '{print $2}')

# Calculate data consumed
downloaded_consumed=$((final_downloaded - initial_downloaded))
uploaded_consumed=$((final_uploaded - initial_uploaded))

echo "Expected data download: $NUM_MB MB."
# echo "Actual data downloaded: $((downloaded_consumed / 1024)) MB."
# echo "Actual data uploaded: $((uploaded_consumed / 1024)) MB."
echo "Actual data downloaded: $((downloaded_consumed)) MB."
echo "Actual data uploaded: $((uploaded_consumed)) MB."

