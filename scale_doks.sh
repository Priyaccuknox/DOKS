#!/bin/bash

# Load required variables
clusters=$(yq '.clusters | length' config.yaml)

# Check if the operation is passed (scale-up or scale-down)
operation=$1
if [[ "$operation" != "scale-up" && "$operation" != "scale-down" ]]; then
  echo "Please provide a valid operation: scale-up or scale-down."
  exit 1
fi

# Perform the scaling operation for each cluster
for i in $(seq 0 $(($clusters - 1))); do
  CLUSTER_NAME=$(yq ".clusters[$i].name" config.yaml)
  CLUSTER_ID=$(yq ".clusters[$i].cluster_id" config.yaml)
  NODE_POOL_ID=$(yq ".clusters[$i].node_pool_id" config.yaml)

  if [ "$operation" == "scale-up" ]; then
    NODE_COUNT=$(yq ".clusters[$i].scale_up_count" config.yaml)
  else
    NODE_COUNT=$(yq ".clusters[$i].scale_down_count" config.yaml)
  fi

  echo "Performing $operation for cluster $CLUSTER_NAME..."
  echo "Setting node pool count to $NODE_COUNT..."

  # Perform the scaling operation
  curl -X PUT \
    -H "Authorization: Bearer $DO_USER" \
    -H "Content-Type: application/json" \
    -d "{\"count\": ${NODE_COUNT}}" \
    "https://api.digitalocean.com/v2/kubernetes/clusters/${CLUSTER_ID}/node_pools/${NODE_POOL_ID}"

  echo "$operation completed for cluster $CLUSTER_NAME."
done
