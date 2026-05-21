#!/bin/bash
source "/home/steam/server/functions.sh"

SERVER_FILES="/home/steam/server-files"

cd "$SERVER_FILES" || exit

LogAction "Starting V Rising Dedicated Server"

GAME_PORT="${GAME_PORT:-27015}"
QUERY_PORT="${QUERY_PORT:-27016}"
SERVER_NAME="${SERVER_NAME:-vrising-server}"
MAX_USERS="${MAX_USERS:-40}"
SAVE_NAME="${SAVE_NAME:-world1}"
SERVER_FPS="${SERVER_FPS:-30}"

SERVER_EXEC="$SERVER_FILES/VRisingServer.exe"

if [ ! -f "$SERVER_EXEC" ]; then
    LogError "Could not find server executable at: $SERVER_EXEC"
    LogError "Directory contents:"
    ls -laR "$SERVER_FILES/"
    exit 1
fi

LogInfo "Found server executable: ${SERVER_EXEC}"
LogInfo "Server starting on port ${GAME_PORT}"
LogInfo "Query port: ${QUERY_PORT}"
LogInfo "Server name: ${SERVER_NAME}"
LogInfo "Max users: ${MAX_USERS}"

export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDEBUG="${WINEDEBUG:-fixme-all}"

if [ ! -f "$WINEPREFIX/system.reg" ]; then
    LogInfo "Initializing Wine prefix..."
    winecfg -v win10 >/dev/null 2>&1
    wineboot --init >/dev/null 2>&1
    LogInfo "Wine initialized: $(wine --version)"
fi

STARTUP_CMD="xvfb-run --auto-servernum wine ${SERVER_EXEC} -persistentDataPath ${SERVER_FILES}/data -serverName \"${SERVER_NAME}\" -saveName \"${SAVE_NAME}\" -gamePort ${GAME_PORT} -queryPort ${QUERY_PORT} -maxUsers ${MAX_USERS} -fps ${SERVER_FPS}"

LogInfo "Starting with Wine..."

eval "$STARTUP_CMD"
