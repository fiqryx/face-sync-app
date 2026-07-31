#!/bin/bash

echo "[BOOT] Starting Face-Sync initialization..."
sleep 3

FLAG_DIR="/app/flag"
KEY_FILE="$FLAG_DIR/app.key"
DB_FLAG_FILE="$FLAG_DIR/db_init.flag"

# ==========================================
# 1. RESOLVE KEY PERSISTENCE
# ==========================================
if [ ! -f "$KEY_FILE" ]; then
    # handle "down -v" to keep the key. (eg backup -> reset database, etc)
    # if not need just change manually or make the KEY is blank to regenerate
    CURRENT_KEY=$(grep '^KEY=' /app/.env | cut -d'=' -f2- | tr -d '"')
    if [ -z "$CURRENT_KEY" ]; then
        echo "[BOOT] KEY is empty. Generating new key..."
        ./backend generate:key
        sed -i 's/\r$//' /app/.env
        GENERATED_KEY=$(grep '^KEY=' /app/.env | cut -d'=' -f2- | tr -d '"')
        echo -n "$GENERATED_KEY" > "$KEY_FILE"
    else
        echo "[BOOT] Existing KEY found in .env, skipping generation."
        echo -n "$CURRENT_KEY" > "$KEY_FILE"
    fi
else
    echo "[BOOT] Restoring persisted key into .env..."
    PERSISTED_KEY=$(cat "$KEY_FILE" | tr -d '\r' | tr -d '\n')
    sed "s@^KEY=.*@KEY=\"${PERSISTED_KEY}\"@" /app/.env > /app/.env.tmp
    cat /app/.env.tmp > /app/.env
    rm /app/.env.tmp
fi

# ==========================================
# 2. LOAD .ENV
# ==========================================
if [ -f /app/.env ]; then
    sed -i 's/\r$//' /app/.env
    set -a
    source /app/.env
    set +a
fi

export PIPER_PORT="${PIPER_PORT:-5500}"
export WEBUI_PORT="${WEBUI_PORT:-3000}"

# ==========================================
# 3. DATABASE SETUP 
# ==========================================
# echo "[BOOT] Sync database..."
# ./backend migrate

if [ ! -f "$DB_FLAG_FILE" ]; then
    echo "[BOOT] Fresh environment detected. Running setup environment..."
    ./backend db:seed
    touch "$DB_FLAG_FILE"
    echo "[BOOT] Setup completed. Flag file created."
fi

echo "[BOOT] System is secure! Starting all services via Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf