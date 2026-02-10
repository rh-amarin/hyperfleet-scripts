#!/bin/bash
# Configure PostgreSQL database connection parameters
# Usage: hf.db.config.sh
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

echo -e "${BOLD}Configure PostgreSQL Connection${NC}"
echo ""

# Read current values or use defaults
read -p "DB Host [$HF_DB_HOST]: " db_host
db_host="${db_host:-$HF_DB_HOST}"
[[ -z "$db_host" ]] && db_host="localhost"

read -p "DB Port [$HF_DB_PORT]: " db_port
db_port="${db_port:-$HF_DB_PORT}"
[[ -z "$db_port" ]] && db_port="5432"

read -p "DB Name [$HF_DB_NAME]: " db_name
db_name="${db_name:-$HF_DB_NAME}"

read -p "DB User [$HF_DB_USER]: " db_user
db_user="${db_user:-$HF_DB_USER}"

# Password input (hidden)
if [[ -n "$HF_DB_PASSWORD" ]]; then
    read -sp "DB Password [current: <set>]: " db_password
else
    read -sp "DB Password (leave empty to use .pgpass or prompt): " db_password
fi
echo ""

# Save configuration
hf_set_db_host "$db_host"
hf_set_db_port "$db_port"

if [[ -n "$db_name" ]]; then
    hf_set_db_name "$db_name"
else
    hf_warn "DB name not set"
fi

if [[ -n "$db_user" ]]; then
    hf_set_db_user "$db_user"
else
    hf_warn "DB user not set"
fi

if [[ -n "$db_password" ]]; then
    hf_set_db_password "$db_password"
else
    # Clear password if empty was entered
    rm -f "$HF_DB_PASSWORD_FILE"
    hf_info "DB password cleared (will use .pgpass or prompt)"
fi

echo ""
hf_info "Database configuration saved to: $HF_CONFIG_DIR"
echo ""
echo "Test connection with:"
echo "  hf.db.query.sh 'SELECT version()'"
