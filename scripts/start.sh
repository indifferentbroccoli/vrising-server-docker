#!/usr/bin/env bash
source "/home/steam/server/functions.sh"
set -euo pipefail

SERVER_DIR=/data/server
SAVES_DIR=/data/saves
CONFIG_DIR=/data/config
PLUGINS_DIR=/data/plugins
BACKUP_DIR=/data/backups
LOG_FILE="$SAVES_DIR/logs/VRisingServer.log"
RCON_PASSWORD="${RCON_PASSWORD:-}"

# Configure RCON settings
if [[ -z "${RCON_PASSWORD}" ]]; then
    RCON_PASSWORD=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)
    LogInfo "No RCON_PASSWORD set - generated an internal one for this run"
fi

LogInfo "Configuring RCON settings"
cat >/home/steam/server/rcon.yml  <<EOL
default:
  address: "127.0.0.1:${RCON_PORT}"
  password: ${RCON_PASSWORD}
EOL

mkdir -p "$SAVES_DIR/logs" "$CONFIG_DIR/game" "$BACKUP_DIR"

link_dir "$CONFIG_DIR/game" "$SAVES_DIR/Settings"
SETTINGS_SRC="$SERVER_DIR/VRisingServer_Data/StreamingAssets/Settings"
for f in ServerHostSettings.json ServerGameSettings.json; do
  if [[ ! -f "$CONFIG_DIR/game/$f" && -f "$SETTINGS_SRC/$f" ]]; then
    LogInfo "Seeding default $f"
    cp "$SETTINGS_SRC/$f" "$CONFIG_DIR/game/$f"
  fi
done

LogInfo "Configuring mods"
enable_disable_mods

SERVER_PID=""
TAIL_PID=""

HOST_SETTINGS="$CONFIG_DIR/game/ServerHostSettings.json"

update_json "$HOST_SETTINGS" '.Rcon.Password = $pw | .Rcon.Enabled = true' \
  --arg pw "$RCON_PASSWORD"

trap shutdown SIGTERM SIGINT

backup_server

launch=(wine "$SERVER_DIR/VRisingServer.exe"
  -persistentDataPath "$SAVES_DIR"
  -serverName "$SERVER_NAME"
  -saveName "$SAVE_NAME"
  -logFile -)

if command -v xvfb-run >/dev/null 2>&1; then
  launch=(xvfb-run --auto-servernum "${launch[@]}")
else
  LogInfo "Xvfb not installed, launching without a virtual display"
fi

log_cycle
LogInfo "Starting: ${launch[*]}"
cd "$SERVER_DIR"
"${launch[@]}" > >(tee -a "$LOG_FILE") 2>&1 &
SERVER_PID=$!

set +e
wait "$SERVER_PID"
status=$?
set -e

LogInfo "Server exited with status $status"
kill "$TAIL_PID" 2>/dev/null || true
exit "$status"