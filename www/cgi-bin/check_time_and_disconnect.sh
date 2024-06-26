# #!/bin/sh

#!/bin/sh -e
set -x

LOGFILE="/var/log/nodogsplash_data_purchases.json"
USAGE_LOGFILE="/var/log/nodogsplash_data_usage.json"

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

compare_and_update_usage_log() {
  client_usage=$(ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.duration) \(.value.token)"')

  echo "$client_usage" | while read -r mac duration token; do
    current_duration=$(jq -r --arg token "$token" '.[$token].duration // 0' "$USAGE_LOGFILE")

    if [ "$duration" -gt "$current_duration" ]; then
      update_usage_log "$mac" "$duration" "$token"
    fi
  done
}

update_usage_log() {
  local mac="$1"
  local duration="$2"
  local token="$3"

  read_usage_log

  new_entry=$(jq -n --arg mac "$mac" --argjson duration "$duration" --arg token "$token" '{
    ($token): {
      "mac": $mac,
      "duration": $duration,
      "token": $token
    }
  }')

  updated_usage=$(echo "$usage_data" | jq --argjson new_entry "$new_entry" 'reduce ($new_entry | to_entries[]) as $i (.; .[$i.key] |= . + $i.value)')

  echo "$updated_usage" > "$USAGE_LOGFILE"
}

read_usage_log() {
  if [ ! -f "$USAGE_LOGFILE" ]; then
    echo "{}" > "$USAGE_LOGFILE"
  fi

  usage_data=$(cat "$USAGE_LOGFILE")
}

disconnect_clients_if_exceeded_time() {
  client_usage=$(ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.duration) \(.value.token)"')

  echo "$client_usage" | while read -r mac duration token; do
    associated_token=$(echo "$paid_data" | awk -v mac="$mac" '$1 == mac {print $3}')

    if [ -z "$associated_token" ]; then
      continue
    fi

    session_time=$(jq -r --arg token "$associated_token" '.[] | select(.token == $token) | .sessiontime' "$LOGFILE")

    if [ "$duration" -gt "$session_time" ]; then
      ndsctl deauth "$mac"
      echo "$mac: Disconnected after $duration seconds, Session time limit $session_time seconds"
    fi
  done
}

# Main
paid_data=$(get_paid_data)
compare_and_update_usage_log
disconnect_clients_if_exceeded_time

