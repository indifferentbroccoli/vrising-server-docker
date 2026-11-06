#!/bin/bash
source /home/steam/server/functions.sh

cat /branding

if [ ! -w "$SERVER_DIR" ]; then
  LogError "$SERVER_DIR is not writable by user $(id -u):$(id -g)"
  LogError "Give the folder you mounted to that user, e.g. sudo chown -R $(id -u):$(id -g) ./server-files"
  exit 1
fi

if [ ! -f "$WINEPREFIX/system.reg" ]; then
  LogAction "Setting up Wine"
  wineboot --init && wineserver -w
fi

if [ "$UPDATE_ON_START" = "true" ] || ! server_is_installed; then
  if ! install_server; then
    server_is_installed || exit 1
    LogWarn "Update failed, starting the installed version"
  fi
else
  LogWarn "UPDATE_ON_START is false, skipping server update"
fi

stop_server() {
  LogWarn "Stopping server..."
  pkill -INT -f VRisingServer.exe
  wait "$server_pid"
}
trap stop_server SIGTERM

./start.sh &
server_pid=$!
wait "$server_pid"
