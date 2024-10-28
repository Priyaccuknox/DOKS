#!/bin/bash

# Load required variables from GKE/config.yaml
clusters=$(yq '.clusters | length' GKE/config.yaml)

# Check if the operation is passed (scale-up or scale-down)
operation=$1
if [[ "$operation" != "scale-up" && "$operation" != "scale-down" ]]; then
  echo "Please provide a valid operation: scale-up or scale-down."
  exit 1
fi

# Perform the scaling operation for each cluster
for i in $(seq 0 $(($clusters - 1))); do
  CLUSTER_NAME=$(yq ".clusters[$i].name" GKE/config.yaml)
  CLUSTER_ID=$(yq ".clusters[$i].cluster_id" GKE/config.yaml)
  NODE_POOL_ID=$(yq ".clusters[$i].node_pool_id" GKE/config.yaml)

  if [ "$operation" == "scale-up" ]; then
    NODE_COUNT=$(yq ".clusters[$i].scale_up_count" GKE/config.yaml)
  else
    NODE_COUNT=$(yq ".clusters[$i].scale_down_count" GKE/config.yaml)
  fi

  echo "Performing $operation for cluster $CLUSTER_NAME..."
  echo "Setting node pool count to $NODE_COUNT..."

  # Perform the scaling operation
  gcloud container clusters resize $CLUSTER_NAME \
    --node-pool $NODE_POOL_ID \
    --num-nodes $NODE_COUNT \
    --quiet

  echo "$operation completed for cluster $CLUSTER_NAME."
done
