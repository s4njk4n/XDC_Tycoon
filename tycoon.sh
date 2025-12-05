#!/bin/bash

# XDC Tycoon v1.0 - Open-source XDC masternode monitor
# Fork from https://github.com/s4njk4n/XDC_Tycoon

# Variables Section
CSV_FILE="tycoon_nodes.csv"  # Path to CSV file
API_BASE="https://master.xinfin.network/api/candidates/"
EXPLORER_API="https://api.etherscan.io/v2/api"  # Etherscan V2 API endpoint (multichain)
CHAIN_ID="50"  # Chain ID for XDC mainnet
API_KEY_FILE="api_key.txt"  # File containing Etherscan API key
STATE_FILE="state.json"  # File to store previous states
LOG_FILE="log.txt"  # File for logging
RETRIES=3  # Number of retries for API calls
SLEEP=5  # Seconds to wait between retries
REWARD_AMOUNTS=("22500000000000000000000" "66666000000000000000000")  # 22500 XDC and 66666 XDC in wei
NTFY_SERVER="ntfy.sh"  # ntfy server URL without https://
TIMEOUT=10  # Timeout for curl in seconds

if [ ! -f "$CSV_FILE" ]; then
  echo "Error: $CSV_FILE not found."
  exit 1
fi

if [ ! -f "$API_KEY_FILE" ]; then
  echo "Error: api_key.txt not found."
  exit 1
fi

API_KEY=$(cat "$API_KEY_FILE")

# Logging function
write_to_log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Clean log entries older than 48 hours
clean_log() {
  if [ -f "$LOG_FILE" ]; then
    local cutoff=$(date -d "48 hours ago" '+%s')
    awk -v cutoff="$cutoff" -F ' - ' '
    BEGIN { FS = " - "; OFS = " - " }
    {
      split($1, dt, " ");
      date_str = dt[1];
      time_str = dt[2];
      split(date_str, d, "-");
      split(time_str, t, ":");
      ts = mktime(d[1] " " d[2] " " d[3] " " t[1] " " t[2] " " t[3])
      if (ts >= cutoff) print $0
    }' "$LOG_FILE" > temp_log.txt && mv temp_log.txt "$LOG_FILE"
  fi
}

# Clean log at start
clean_log

# Load previous state if exists
if [ -f "$STATE_FILE" ]; then
  PREVIOUS_STATES=$(cat "$STATE_FILE")
else
  PREVIOUS_STATES="{}"
fi

# New state to update at end
NEW_STATES="$PREVIOUS_STATES"

# Flag for dApp unresponsive
UNRESPONSIVE=false

# Array for ntfy topics
declare -a NTFY_TOPICS

# Function to send ntfy notification
send_ntfy_notification() {
    local topic="$1"
    local message="$2"
    if curl -s -m "$TIMEOUT" -d "$message" "$NTFY_SERVER/$topic" >/dev/null; then
        write_to_log "Notification sent to $topic: $message"
    else
        write_to_log "Failed to send notification to $topic"
    fi
}

# Function to get AEST timestamp
get_aest_timestamp() {
    TZ='Australia/Sydney' date '+%Y-%m-%d %H:%M:%S'
}

# Function to query status for a candidate
get_status() {
  local CANDIDATE="$1"
  local RESPONSE=""
  for ((attempt=1; attempt<=$RETRIES; attempt++)); do
    RESPONSE=$(curl -s "$API_BASE$CANDIDATE")
    if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq . > /dev/null 2>&1; then
      break
    fi
    if [ $attempt -lt $RETRIES ]; then
      sleep $SLEEP
    fi
  done

  if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | jq . > /dev/null 2>&1; then
    UNRESPONSIVE=true
    return 1
  fi

  local STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')
  if [ -n "$STATUS" ]; then
    echo "$STATUS"
  else
    echo "DISAPPEARED"
  fi
}

# Function to check for reward transactions on owner address since last check
check_rewards() {
  local OWNER="$1"
  local NTFY_TOPIC="$2"
  local NODE_NAME="$3"
  local CANDIDATE_SHORT="${4: -4}"
  local OWNER_SHORT="${OWNER: -4}"
  local LAST_TIME=$(echo "$PREVIOUS_STATES" | jq -r ".\"$OWNER\" // 0")

  local CURRENT_TIME=$(date +%s)

  # On first run, limit to last 24 hours
  if [ "$LAST_TIME" = "0" ]; then
    LAST_TIME=$((CURRENT_TIME - 86400))  # 24 hours in seconds
    # echo "Debug: First run - setting LAST_TIME to 24 hours ago: $LAST_TIME"
  fi

  # echo "Debug: Fetching transactions for owner $OWNER with last_time $LAST_TIME"

  # Fetch transactions from Etherscan V2 (sort desc for recent first)
  local TX_RESPONSE=$(curl -s "$EXPLORER_API?chainid=$CHAIN_ID&module=account&action=txlist&address=$OWNER&sort=desc&apikey=$API_KEY")

  # echo "Debug: API URL: $EXPLORER_API?chainid=$CHAIN_ID&module=account&action=txlist&address=$OWNER&sort=desc&apikey=REDACTED"

  local JQ_STATUS=$(echo "$TX_RESPONSE" | jq -r '.status' 2>/dev/null)
  local JQ_MESSAGE=$(echo "$TX_RESPONSE" | jq -r '.message' 2>/dev/null)
  # echo "Debug: TX_RESPONSE status: $JQ_STATUS, message: $JQ_MESSAGE"

  if [ "$JQ_STATUS" != "1" ]; then
    # echo "Debug: Full TX_RESPONSE: $TX_RESPONSE"
    write_to_log "Error fetching transactions for owner $OWNER: $JQ_MESSAGE"
    return 1
  fi

  local TXS=$(echo "$TX_RESPONSE" | jq -r '.result[] | .timeStamp + ":" + .to + ":" + .value' 2>/dev/null)
  local PROCESSED=0
  while IFS= read -r tx; do
    local TX_TIME=$(echo "$tx" | cut -d: -f1)
    local TO=$(echo "$tx" | cut -d: -f2)
    local VALUE=$(echo "$tx" | cut -d: -f3)

    # echo "Debug: Processing tx: time=$TX_TIME, to=$TO, value=$VALUE"

    if ! [[ "$TX_TIME" =~ ^[0-9]+$ ]]; then
      # echo "Debug: Invalid TX_TIME: $TX_TIME - skipping"
      continue
    fi

    if [ "$TX_TIME" -le "$LAST_TIME" ]; then
      # echo "Debug: Reached older transaction at $TX_TIME <= $LAST_TIME - breaking"
      break
    fi

    if [ "${TO,,}" = "${OWNER,,}" ]; then
      for amount in "${REWARD_AMOUNTS[@]}"; do
        if [ "$VALUE" = "$amount" ]; then
          local XDC_AMOUNT=$(echo "$VALUE / 1000000000000000000" | bc)
          local TIMESTAMP=$(get_aest_timestamp)
          # local MESSAGE="XDC Tycoon: Node $NODE_NAME (candidate ...$CANDIDATE_SHORT, owner ...$OWNER_SHORT) - Potential reward distribution of $XDC_AMOUNT XDC! Timestamp: $TIMESTAMP"
          local MESSAGE="XDC Tycoon: $NODE_NAME (candidate ...$CANDIDATE_SHORT, owner ...$OWNER_SHORT) - Potential reward distribution of $XDC_AMOUNT XDC!"
          echo "$MESSAGE"
          write_to_log "$MESSAGE"
          if [ -n "$NTFY_TOPIC" ]; then
            send_ntfy_notification "$NTFY_TOPIC" "$MESSAGE"
          fi
        fi
      done
    fi
    ((PROCESSED++))
  done <<< "$TXS"
  # echo "Debug: Processed $PROCESSED transactions"

  # Update last time
  NEW_STATES=$(echo "$NEW_STATES" | jq --arg key "$OWNER" --arg val "$CURRENT_TIME" '.[$key] = $val')
}

# Determine if we should send daily status
current_time=$(date +%s)
current_aest_date=$(TZ='Australia/Sydney' date -d "@$current_time" +%Y-%m-%d)
current_aest_hour=$(TZ='Australia/Sydney' date -d "@$current_time" +%H)
last_daily_date=$(echo "$PREVIOUS_STATES" | jq -r '."last_daily_notification_date" // ""')
send_daily=false
if [ "$current_aest_hour" -ge 8 ] && [ "$last_daily_date" != "$current_aest_date" ]; then
  send_daily=true
fi

# Skip header and process each line
while IFS=',' read -r node_name candidate owner_address ntfy_topic; do
  if [ -z "$candidate" ]; then continue; fi
  candidate="${candidate#xdc}"
  candidate="xdc${candidate,,}"

  owner_address="${owner_address#xdc}"
  owner_address="0x${owner_address,,}"

  # Load previous status
  previous_status=$(echo "$PREVIOUS_STATES" | jq -r ".\"$candidate\" // \"UNKNOWN\"")

  # Query status
  current_status=""
  for ((attempt=1; attempt<=$RETRIES; attempt++)); do
    RESPONSE=$(curl -s "$API_BASE$candidate")
    if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq . > /dev/null 2>&1; then
      STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')
      if [ -n "$STATUS" ]; then
        current_status="$STATUS"
      else
        current_status="DISAPPEARED"
      fi
      break
    fi
    if [ $attempt -lt $RETRIES ]; then
      sleep $SLEEP
    else
      UNRESPONSIVE=true
    fi
  done

  if [ "$UNRESPONSIVE" = true ]; then
    TIMESTAMP=$(get_aest_timestamp)
    # MESSAGE="XDC Tycoon: Node $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) - Governance dApp is unresponsive! Timestamp: $TIMESTAMP"
    MESSAGE="XDC Tycoon: $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) - Governance dApp is unresponsive!"
    echo "$MESSAGE"
    write_to_log "$MESSAGE"
    if [ -n "$ntfy_topic" ]; then
      send_ntfy_notification "$ntfy_topic" "$MESSAGE"
    fi
    continue
  fi

  # echo "Node $node_name ($candidate) status: $current_status (previous: $previous_status)"
  # write_to_log "Node $node_name ($candidate) status: $current_status (previous: $previous_status)"

  if [ "$current_status" != "$previous_status" ]; then
    TIMESTAMP=$(get_aest_timestamp)
    # MESSAGE="XDC Tycoon: Node $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) changed from $previous_status to $current_status! Timestamp: $TIMESTAMP"
    MESSAGE="XDC Tycoon: $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) changed from $previous_status to $current_status!"
    echo "$MESSAGE"
    write_to_log "$MESSAGE"
    if [ -n "$ntfy_topic" ]; then
      send_ntfy_notification "$ntfy_topic" "$MESSAGE"
    fi
  fi

  if [ "$current_status" = "SLASHED" ] || [ "$current_status" = "RESIGNED" ] || [ "$current_status" = "DISAPPEARED" ]; then
    TIMESTAMP=$(get_aest_timestamp)
    # MESSAGE="XDC Tycoon: Node $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) is $current_status! Timestamp: $TIMESTAMP"
    MESSAGE="XDC Tycoon: $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) is $current_status!"
    echo "$MESSAGE"
    write_to_log "$MESSAGE"
    if [ -n "$ntfy_topic" ]; then
      send_ntfy_notification "$ntfy_topic" "$MESSAGE"
    fi
  fi

  # Send daily status if applicable
  if [ "$send_daily" = true ]; then
    TIMESTAMP=$(get_aest_timestamp)
    # MESSAGE="XDC Tycoon: Node $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) status is $current_status. Timestamp: $TIMESTAMP"
    MESSAGE="XDC Tycoon: $node_name (candidate ...${candidate: -4}, owner ...${owner_address: -4}) status is $current_status."
    echo "$MESSAGE"
    write_to_log "$MESSAGE"
    if [ -n "$ntfy_topic" ]; then
      send_ntfy_notification "$ntfy_topic" "$MESSAGE"
    fi
  fi

  # Update status in new state
  NEW_STATES=$(echo "$NEW_STATES" | jq --arg key "$candidate" --arg val "$current_status" '.[$key] = $val')

  # Check rewards for owner
  check_rewards "$owner_address" "$ntfy_topic" "$node_name" "$candidate"
done < <(tail -n +2 "$CSV_FILE")

# Handle unresponsive dApp (global)
if [ "$UNRESPONSIVE" = true ]; then
  TIMESTAMP=$(get_aest_timestamp)
  # MESSAGE="XDC Tycoon: Governance dApp is unresponsive! Timestamp: $TIMESTAMP"
  MESSAGE="XDC Tycoon: Governance dApp is unresponsive!"
  echo "$MESSAGE"
  write_to_log "$MESSAGE"
  # Global alert if needed
fi

# Update daily notification date if sent
if [ "$send_daily" = true ]; then
  NEW_STATES=$(echo "$NEW_STATES" | jq --arg val "$current_aest_date" '."last_daily_notification_date" = $val')
fi

# Save new state
echo "$NEW_STATES" > "$STATE_FILE"
