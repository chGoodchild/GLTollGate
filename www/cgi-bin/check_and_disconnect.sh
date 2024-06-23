#!/bin/sh

# #!/bin/sh -e
# set -x


# Path to the nodogsplash data purchases log
LOGFILE="/var/log/nodogsplash_data_purchases.json"

# Function to get the total data paid for each MAC address
get_paid_data() {
  jq -r '.[] | "\(.mac) \(.data_amount)"' "$LOGFILE" | awk '
    {
      mac[$1] += $2
    }
    END {
      for (m in mac) {
        print m, mac[m]
      }
    }'
}

# Function to get the current data usage of each client
get_client_usage() {
  ndsctl json | jq -r '.clients | to_entries[] | "\(.key) \(.value.downloaded) \(.value.uploaded)"'
}

# Get the paid data
paid_data=$(get_paid_data)

# Get the client usage
client_usage=$(get_client_usage)

# Verbose flag
VERBOSE=true

# Compare and disconnect if necessary
echo "$client_usage" | while read -r mac downloaded uploaded; do
  total_data_used=$(awk "BEGIN {print $downloaded + $uploaded}")
  total_data_paid=$(echo "$paid_data" | awk -v mac="$mac" '$1 == mac {print $2}')
  
  if [ -n "$total_data_paid" ] && [ "$(awk "BEGIN {print ($total_data_used > $total_data_paid)}")" -eq 1 ]; then
    echo "Disconnecting $mac: Used $total_data_used KB, Paid for $total_data_paid KB"
    ndsctl deauth "$mac"
  else
    if [ "$VERBOSE" = true ]; then
      data_left=$(awk "BEGIN {print $total_data_paid - $total_data_used}")
      echo "$mac: Used $total_data_used KB, Paid for $total_data_paid KB, Data left $data_left KB"
    fi
  fi
done


