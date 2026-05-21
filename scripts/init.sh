#!/bin/bash
source "/home/steam/server/functions.sh"

LogAction "Set file permissions"

if [ -z "${PUID}" ] || [ -z "${PGID}" ]; then
    LogError "PUID and PGID not set. Please set these in the environment variables."
    exit 1
else
    usermod -o -u "${PUID}" steam
    groupmod -o -g "${PGID}" steam
fi

chown -R steam:steam /home/steam/

cat /branding

if [ "${UPDATE_ON_START:-true}" = "true" ]; then
    install
else
    LogWarn "UPDATE_ON_START is set to false, skipping server update from Steam"
fi

chown -R steam:steam /home/steam/server-files

term_handler() {
    if ! shutdown_server; then
        kill -SIGTERM "$(pidof wine-preloader)"
    fi
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

export GAME_PORT
export QUERY_PORT
export SERVER_NAME
export MAX_USERS
export SAVE_NAME
export SERVER_FPS

su - steam -c "cd /home/steam/server && GAME_PORT='${GAME_PORT}' QUERY_PORT='${QUERY_PORT}' SERVER_NAME='${SERVER_NAME}' MAX_USERS='${MAX_USERS}' SAVE_NAME='${SAVE_NAME}' SERVER_FPS='${SERVER_FPS}' ./start.sh" &

killpid="$!"
wait "$killpid"
