#!/bin/bash

# Load required variables
clusters=$(yq '.clusters | length' config.yaml)

# Check if the operation is passed (scale-up or scale-down)
operation=$1
if [[ "$operation" != "scale-up" && "$operation" != "scale-down" ]]; then
  echo "Please provide a valid operation: scale-up or scale-down."
  exit 1
fi

# Check if the service account key file exists
if [[ ! -f "gcp-key.json" ]]; then
  echo "Error: Service account key file not found: gcp-key.json"
  exit 1
fi

# Activate GCP service account
echo "Activating service account..."
gcloud auth activate-service-account --key-file="gcp-key.json" || {
  echo "Error: Failed to activate service account."
  exit 1
}

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

  # Perform the scaling operation using gcloud command
  gcloud container clusters resize "$CLUSTER_ID" \
    --node-pool "$NODE_POOL_ID" \
    --num-nodes "$NODE_COUNT" \
    --quiet || {
    echo "Error: Failed to resize the node pool."
    exit 1
  }

  echo "$operation completed for cluster $CLUSTER_NAME."
done
