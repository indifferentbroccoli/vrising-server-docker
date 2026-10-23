#!/bin/bash
source "/home/steam/server/functions.sh"

cat /branding

if [[ ! -f "$SERVER_DIR/VRisingServer.exe" ]]; then
    LogError "No server found, installing branch '$STEAM_BRANCH'"
    update_server
elif [[ "$UPDATE_ON_START" == "true" ]]; then
    LOCAL=$(local_buildid)
    REMOTE=$(remote_buildid)
    LogInfo "Installed build: $LOCAL / Available build: ${REMOTE:-unknown}"
    if [[ -n "$REMOTE" && "$REMOTE" != "$LOCAL" ]]; then
        backup_server
        update_server || LogError "Update failed - starting existing build $LOCAL"
    else
        LogInfo "Server is up to date"
    fi
else
    LogInfo "UPDATE_ON_START=false, keeping build $(local_buildid)"
fi

term_handler() {
    if ! shutdown; then
        kill -SIGTERM "$(pidof VRisingServer.exe)" 2>/dev/null || true
    fi
    tail --pid="$killpid" -f 2>/dev/null
}

trap 'term_handler' SIGTERM

/home/steam/server/start.sh &

killpid="$!"
wait "$killpid"