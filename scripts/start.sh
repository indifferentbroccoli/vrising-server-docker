#!/bin/bash
source /home/steam/server/functions.sh

cd "$SERVER_DIR" || exit 1

rotate_log
seed_settings
configure_rcon
configure_mods

args=(
  -persistentDataPath "$DATA_DIR"
  -serverName "$SERVER_NAME"
  -saveName "$SAVE_NAME"
  -logFile -
)

LogAction "Starting server"
LogInfo "Arguments: ${args[*]}"

exec xvfb-run --auto-servernum wine VRisingServer.exe "${args[@]}" > >(tee -a "$LOG_FILE") 2>&1
