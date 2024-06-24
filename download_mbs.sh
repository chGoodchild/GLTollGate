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

# Check if iftop is installed, install if necessary
if ! command -v iftop &> /dev/null; then
  echo "iftop not found, installing..."
  sudo apt-get update
  sudo apt-get install -y iftop
fi

# Function to get downloaded and uploaded data from ndsctl json
get_data_usage() {
  sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "ndsctl json" | jq '.clients[] | .downloaded, .uploaded'
}

# Function to get current iftop data usage
get_iftop_usage() {
  sudo iftop -t -s 1 -n -N -i <interface> | awk 'NR==6{print $2,$4}' | tr -d 'KMG' | awk '{print $1*1024, $2*1024}'
}

# Retrieve initial data usage from ndsctl
initial_data=$(get_data_usage)
initial_downloaded=$(echo $initial_data | awk '{print $1}')
initial_uploaded=$(echo $initial_data | awk '{print $2}')

# Retrieve initial data usage from iftop
initial_iftop_data=$(get_iftop_usage)
initial_iftop_downloaded=$(echo $initial_iftop_data | awk '{print $1}')
initial_iftop_uploaded=$(echo $initial_iftop_data | awk '{print $2}')

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

# Retrieve final data usage from ndsctl
final_data=$(get_data_usage)
final_downloaded=$(echo $final_data | awk '{print $1}')
final_uploaded=$(echo $final_data | awk '{print $2}')

# Retrieve final data usage from iftop
final_iftop_data=$(get_iftop_usage)
final_iftop_downloaded=$(echo $final_iftop_data | awk '{print $1}')
final_iftop_uploaded=$(echo $final_iftop_data | awk '{print $2}')

# Calculate data consumed
downloaded_consumed=$((final_downloaded - initial_downloaded))
uploaded_consumed=$((final_uploaded - initial_uploaded))

# Calculate iftop data consumed
iftop_downloaded_consumed=$((final_iftop_downloaded - initial_iftop_downloaded))
iftop_uploaded_consumed=$((final_iftop_uploaded - initial_iftop_uploaded))

echo "Expected data download: $NUM_MB MB."
echo "Actual data downloaded (ndsctl): $((downloaded_consumed)) MB."
echo "Actual data uploaded (ndsctl): $((uploaded_consumed)) MB."
echo "Actual data downloaded (iftop): $((iftop_downloaded_consumed)) MB."
echo "Actual data uploaded (iftop): $((iftop_uploaded_consumed)) MB."

