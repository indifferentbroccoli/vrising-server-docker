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
)

if [ "$ENABLE_MODS" != "true" ]; then
  args+=(-logFile -)
fi

LogAction "Starting server"
LogInfo "Arguments: ${args[*]}"

if [ -t 0 ]; then
  stty cols 200 rows 50
fi

exec xvfb-run --auto-servernum wine VRisingServer.exe "${args[@]}" > >(tee -a "$LOG_FILE") 2>&1
