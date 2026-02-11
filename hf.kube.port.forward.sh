#!/bin/bash
# Port forward to hyperfleet pods
# Usage: hf.kube.port.forward.sh start|stop|status
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

API_LOCAL_PORT="$HF_PF_API_PORT"
API_REMOTE_PORT="$HF_PF_API_PORT"
PG_LOCAL_PORT="$HF_PF_PG_PORT"
PG_REMOTE_PORT="$HF_PF_PG_PORT"
MAESTRO_HTTP_LOCAL_PORT="$HF_PF_MAESTRO_HTTP_PORT"
MAESTRO_HTTP_REMOTE_PORT="$HF_PF_MAESTRO_HTTP_REMOTE_PORT"
MAESTRO_GRPC_LOCAL_PORT="$HF_PF_MAESTRO_GRPC_PORT"
MAESTRO_GRPC_REMOTE_PORT="$HF_PF_MAESTRO_GRPC_PORT"
MAESTRO_NAMESPACE="$HF_MAESTRO_NAMESPACE"

# Get PID of kubectl port-forward using a specific port
get_port_pid() {
  lsof -ti ":$1" 2>/dev/null | head -1
}

is_port_in_use() {
  [[ -n "$(get_port_pid "$1")" ]]
}

find_namespace() {
  local namespaces=("hyperfleet" "default" "hyperfleet-dev" "hyperfleet-local")

  if [[ -n "$HF_KUBE_NAMESPACE" ]]; then
    echo "$HF_KUBE_NAMESPACE"
    return 0
  fi

  for ns in "${namespaces[@]}"; do
    if hf_kubectl get namespace "$ns" &>/dev/null; then
      if hf_kubectl get pods -n "$ns" -l app=hyperfleet-api --no-headers 2>/dev/null | grep -q .; then
        echo "$ns"
        return 0
      fi
    fi
  done

  hf_die "No namespace found with hyperfleet pods"
}

get_pod() {
  local ns="$1" label="$2"
  local pod
  pod=$(hf_kubectl get pods -n "$ns" -l "app=$label" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  [[ -z "$pod" ]] && pod=$(hf_kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep "$label" | head -1 | awk '{print $1}')
  echo "$pod"
}

create_forward() {
  local ns="$1" pod="$2" local_port="$3" remote_port="$4" service="$5"

  [[ -z "$pod" ]] && {
    hf_error "No pod found for $service"
    return 1
  }

  if is_port_in_use "$local_port"; then
    hf_warn "Port $local_port already in use - skipping $service"
    return 0
  fi

  hf_info "Port forwarding $service: localhost:$local_port -> $pod:$remote_port"
  hf_kubectl port-forward -n "$ns" "$pod" "$local_port:$remote_port" &>/dev/null &
  local pid=$!

  sleep 1
  if kill -0 "$pid" 2>/dev/null; then
    hf_info "Established (PID: $pid)"
  else
    hf_error "Failed to create port forward for $service"
    return 1
  fi
}

do_start() {
  hf_require_kubectl

  # Stop any existing forwards first
  if is_port_in_use "$API_LOCAL_PORT" || is_port_in_use "$PG_LOCAL_PORT" ||
    is_port_in_use "$MAESTRO_HTTP_LOCAL_PORT" || is_port_in_use "$MAESTRO_GRPC_LOCAL_PORT"; then
    do_stop
    echo ""
  fi

  echo -e "${BOLD}Starting HyperFleet Port Forwards${NC}\n"

  local ns
  ns=$(find_namespace) || exit 1
  hf_info "Using namespace: $ns"

  local api_pod pg_pod
  api_pod=$(get_pod "$ns" "hyperfleet-api")
  create_forward "$ns" "$api_pod" "$API_LOCAL_PORT" "$API_REMOTE_PORT" "hyperfleet-api"

  pg_pod=$(get_pod "$ns" "postgresql")
  [[ -z "$pg_pod" ]] && pg_pod=$(get_pod "$ns" "postgres")
  create_forward "$ns" "$pg_pod" "$PG_LOCAL_PORT" "$PG_REMOTE_PORT" "postgresql"

  # Maestro server port forwards
  if hf_kubectl get namespace "$MAESTRO_NAMESPACE" &>/dev/null; then
    local maestro_pod
    maestro_pod=$(get_pod "$MAESTRO_NAMESPACE" "maestro")
    create_forward "$MAESTRO_NAMESPACE" "$maestro_pod" "$MAESTRO_HTTP_LOCAL_PORT" "$MAESTRO_HTTP_REMOTE_PORT" "maestro-http"
    create_forward "$MAESTRO_NAMESPACE" "$maestro_pod" "$MAESTRO_GRPC_LOCAL_PORT" "$MAESTRO_GRPC_REMOTE_PORT" "maestro-grpc"
  else
    hf_warn "Maestro namespace '$MAESTRO_NAMESPACE' not found - skipping maestro forwards"
  fi

  echo ""
  sleep 1
  do_status
  echo ""
  hf_info "Use 'hf.kube.port.forward.sh stop' to stop."
}

stop_port() {
  local port="$1" service="$2"
  local pid
  pid=$(get_port_pid "$port")
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null && hf_info "Stopped $service on port $port (PID: $pid)"
  fi
}

do_stop() {
  echo -e "${BOLD}Stopping Port Forwards${NC}\n"

  local stopped=0
  if is_port_in_use "$API_LOCAL_PORT"; then
    stop_port "$API_LOCAL_PORT" "hyperfleet-api"
    ((stopped++))
  fi
  if is_port_in_use "$PG_LOCAL_PORT"; then
    stop_port "$PG_LOCAL_PORT" "postgresql"
    ((stopped++))
  fi
  if is_port_in_use "$MAESTRO_HTTP_LOCAL_PORT"; then
    stop_port "$MAESTRO_HTTP_LOCAL_PORT" "maestro-http"
    ((stopped++))
  fi
  if is_port_in_use "$MAESTRO_GRPC_LOCAL_PORT"; then
    stop_port "$MAESTRO_GRPC_LOCAL_PORT" "maestro-grpc"
    ((stopped++))
  fi

  [[ "$stopped" -eq 0 ]] && hf_info "No port forwards running"

  echo ""
  do_status
}

show_port_status() {
  local port="$1" service="$2"
  local pid
  pid=$(get_port_pid "$port")
  if [[ -n "$pid" ]]; then
    echo -e "  ${GREEN}●${NC} $service - localhost:$port (PID: $pid)"
    return 0
  else
    echo -e "  ${RED}●${NC} $service - localhost:$port (stopped)"
    return 1
  fi
}

do_status() {
  echo -e "${BOLD}Port Forward Status${NC}\n"

  show_port_status "$API_LOCAL_PORT" "hyperfleet-api"
  show_port_status "$PG_LOCAL_PORT" "postgresql"
  show_port_status "$MAESTRO_HTTP_LOCAL_PORT" "maestro-http"
  show_port_status "$MAESTRO_GRPC_LOCAL_PORT" "maestro-grpc"
}

case "${1:-}" in
start) do_start ;;
stop) do_stop ;;
status) do_status ;;
*)
  hf_usage "start|stop|status"
  echo "Commands:"
  echo "  start   Start port forwards to hyperfleet pods"
  echo "  stop    Stop all running port forwards"
  echo "  status  Show status of port forwards"
  ;;
esac
