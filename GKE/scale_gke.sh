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

# Optional: Set the project ID if not already set
PROJECT_ID=$(yq ".project_id" config.yaml)
if [[ -n "$PROJECT_ID" ]]; then
  echo "Setting project to $PROJECT_ID..."
  gcloud config set project "$PROJECT_ID" || {
    echo "Error: Failed to set project."
    exit 1
  }
fi

# Perform the scaling operation for each cluster
for i in $(seq 0 $(($clusters - 1))); do
  CLUSTER_NAME=$(yq ".clusters[$i].name" config.yaml)
  CLUSTER_ID=$(yq ".clusters[$i].cluster_id" config.yaml)
  NODE_POOL_ID=$(yq ".clusters[$i].node_pool_id" config.yaml)
  REGION=$(yq ".clusters[$i].region" config.yaml)

  if [ "$operation" == "scale-up" ]; then
    NODE_COUNT=$(yq ".clusters[$i].scale_up_count" config.yaml)
  else
    NODE_COUNT=$(yq ".clusters[$i].scale_down_count" config.yaml)
  fi

  if [[ -z "$CLUSTER_ID" || -z "$NODE_POOL_ID" || -z "$NODE_COUNT" || -z "$REGION" ]]; then
    echo "Error: Missing required configuration in config.yaml for cluster $CLUSTER_NAME."
    exit 1
  fi

  echo "Performing $operation for cluster $CLUSTER_NAME..."
  echo "Setting node pool count to $NODE_COUNT in region $REGION..."

  # Perform the scaling operation using gcloud command
  gcloud container clusters resize "$CLUSTER_ID" \
    --node-pool "$NODE_POOL_ID" \
    --num-nodes "$NODE_COUNT" \
    --region "$REGION" \
    --quiet || {
    echo "Error: Failed to resize the node pool for cluster $CLUSTER_NAME."
    exit 1
  }

  echo "$operation completed for cluster $CLUSTER_NAME."
done
