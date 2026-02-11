#!/bin/bash
# List maestro resources
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

maestro-cli list --output json --consumer "$HF_MAESTRO_CONSUMER" --http-endpoint "$HF_MAESTRO_HTTP_ENDPOINT"
