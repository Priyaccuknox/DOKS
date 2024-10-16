#!/bin/bash

# Ensure yq is installed (for YAML parsing)
if ! command -v yq &> /dev/null; then
    echo "yq could not be found. Please install yq to proceed."
    exit 1
fi

# Loop through each cluster in the config file and scale it
ACTION=$1  # "scale-up" or "scale-down"
CONFIG_FILE="config.yaml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# Scale each cluster
for cluster in $(yq e '.clusters[] | .name' "$CONFIG_FILE"); do
  CLUSTER_ID=$(yq e ".clusters[] | select(.name == \"$cluster\") | .cluster_id" "$CONFIG_FILE")
  NODE_POOL_ID=$(yq e ".clusters[] | select(.name == \"$cluster\") | .node_pool_id" "$CONFIG_FILE")
  SCALE_UP_COUNT=$(yq e ".clusters[] | select(.name == \"$cluster\") | .scale_up_count" "$CONFIG_FILE")
  SCALE_DOWN_COUNT=$(yq e ".clusters[] | select(.name == \"$cluster\") | .scale_down_count" "$CONFIG_FILE")

  if [ "$ACTION" = "scale-up" ]; then
    echo "Scaling up $cluster to $SCALE_UP_COUNT nodes..."
    doctl kubernetes cluster node-pool update "$CLUSTER_ID" "$NODE_POOL_ID" --count "$SCALE_UP_COUNT"
  elif [ "$ACTION" = "scale-down" ]; then
    echo "Scaling down $cluster to $SCALE_DOWN_COUNT nodes..."
    doctl kubernetes cluster node-pool update "$CLUSTER_ID" "$NODE_POOL_ID" --count "$SCALE_DOWN_COUNT"
  else
    echo "Invalid action specified. Use 'scale-up' or 'scale-down'."
    exit 1
  fi
done
