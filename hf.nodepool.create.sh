#!/bin/bash
# Create a new NodePool under the current cluster
# Usage: hf.nodepool.create.sh <name> [replicas] [instance-type]
source "$(dirname "$(realpath "$0")")/hf.lib.sh"
hf_require_config api-url api-version cluster-id

NAME="${1:-}"
REPLICAS="${2:-2}"
INSTANCE_TYPE="${3:-m5.xlarge}"

[[ -z "$NAME" ]] && {
  hf_usage "<name> [replicas] [instance-type]"
  echo "Arguments:"
  echo "  name            NodePool name (required)"
  echo "  replicas        Number of replicas (default: 2)"
  echo "  instance-type   Instance type (default: m5.xlarge)"
  exit 1
}

hf_require_jq
CLUSTER_ID=$(hf_cluster_id)

hf_info "Creating nodepool '$NAME' in cluster: $CLUSTER_ID"
hf_info "  Replicas: $REPLICAS, Instance type: $INSTANCE_TYPE"

PAYLOAD=$(cat <<EOF
{
  "kind": "NodePool",
  "name": "$NAME",
  "spec": {
    "replicas": $REPLICAS,
    "platform": {
      "type": "$INSTANCE_TYPE"
    }
  }
}
EOF
)

RESPONSE=$(hf_post "/clusters/${CLUSTER_ID}/nodepools" "$PAYLOAD")
echo "$RESPONSE" | jq

# Extract and save the nodepool ID
NODEPOOL_ID=$(echo "$RESPONSE" | jq -r '.id // empty')
if [[ -n "$NODEPOOL_ID" ]]; then
  hf_set_nodepool_id "$NODEPOOL_ID"
fi
