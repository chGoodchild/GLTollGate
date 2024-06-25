# #!/bin/sh

#!/bin/sh -e
set -x

# Path to the nodogsplash data purchases log
LOGFILE="/var/log/nodogsplash_data_purchases.json"

# Path to the nodogsplash data usage log
USAGE_LOGFILE="/var/log/nodogsplash_data_usage.json"

# Maximum allowed connection duration in seconds
TIME_LIMIT=3600  # 1 hour

# Function to get the total data paid for each MAC address
get_paid_data() {
  jq -r '.[] | "\(.mac) \(.data_amount) \(.token // empty)"' "$LOGFILE" | awk '
    {
      mac[$1] += $2
      token[$1] = $3
    }
    END {
      for (m in mac) {
        print m, mac[m], token[m]
      }
    }'
}

# Function to get the current data usage of each client
get_client_usage() {
  ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.duration) \(.value.token)"'
}

# Function to read the usage log
read_usage_log() {
  if [ ! -f "$USAGE_LOGFILE" ]; then
    echo "{}" > "$USAGE_LOGFILE"
  fi
  cat "$USAGE_LOGFILE" | jq '.'
}

# Function to update the usage log
update_usage_log() {
  local mac="$1"
  local duration="$2"
  local token="$3"

  usage_data=$(read_usage_log)

  new_entry=$(jq -n --arg mac "$mac" --argjson duration "$duration" --arg token "$token" \
    '{
      ($token): {
        "mac": $mac,
        "duration": $duration,
        "token": $token
      }
    }')

  updated_usage=$(echo "$usage_data" | jq --argjson new_entry "$new_entry" \
    'reduce ($new_entry | to_entries[]) as $i (.; .[$i.key] |= . + $i.value)')

  echo "$updated_usage" > "$USAGE_LOGFILE"
}

# Function to update token in the purchases log if necessary
update_token_in_purchases_log() {
  local mac="$1"
  local token="$2"

  jq --arg mac "$mac" --arg token "$token" '
    map(if .mac == $mac and (.token == null or .token == "") then .token = $token else . end)' "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
}

# Function to compare and update the usage log if necessary
compare_and_update_usage_log() {
  client_usage=$(get_client_usage)

  echo "$client_usage" | while read -r mac duration token; do
    current_duration=$(jq -r --arg token "$token" '.[$token].duration // 0' "$USAGE_LOGFILE")

    if [ "$duration" -gt "$current_duration" ]; then
      update_usage_log "$mac" "$duration" "$token"
    fi
  done
}

# Get the paid data
paid_data=$(get_paid_data)

# Get the client usage and update usage log
compare_and_update_usage_log

# Verbose flag
VERBOSE=true

# Compare and disconnect if necessary
client_usage=$(get_client_usage)
echo "$client_usage" | while read -r mac duration token; do
  associated_token=$(echo "$paid_data" | awk -v mac="$mac" '$1 == mac {print $3}')
  
  if [ -z "$associated_token" ]; then
    update_token_in_purchases_log "$mac" "$token"
  fi

  if [ "$duration" -gt "$TIME_LIMIT" ]; then
    echo "Disconnecting $mac: Connected for $duration seconds, Time limit $TIME_LIMIT seconds"
    ndsctl deauth "$mac"
  else
    if [ "$VERBOSE" = true ]; then
      time_left=$(awk "BEGIN {print $TIME_LIMIT - $duration}")
      echo "$mac: Connected for $duration seconds, Time limit $TIME_LIMIT seconds, Time left $time_left seconds"
    fi
  fi
done

