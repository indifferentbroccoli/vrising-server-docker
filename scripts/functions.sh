#!/bin/bash
source "/home/steam/server/logging.sh"

log_cycle() {
  if [[ -f "$LOG_FILE" ]]; then
    cp "$LOG_FILE" "$LOG_FOLDER/VRisingServer-$(date +%Y%m%d-%H%M%S).log"
    : > "$LOG_FILE"
  fi
}

rcon-call() {
  local args="$1"
  rcon-cli -c /home/steam/server/rcon.yml "$args"
}

update_json() {
  local file=$1 filter=$2; shift 2
  local tmp
  tmp=$(mktemp "${file}.XXXX")
  jq "$@" "$filter" "$file" > "$tmp" && mv "$tmp" "$file"
}

steamcmd() { /opt/steamcmd/steamcmd.sh "$@"; }

local_buildid() {
  grep -Po '"buildid"\s+"\K\d+' "$SERVER_DIR/steamapps/appmanifest_${APP_ID}.acf" 2>/dev/null || echo 0
}

remote_buildid() {
  steamcmd +login anonymous +app_info_update 1 +app_info_print "$APP_ID" +quit 2>/dev/null \
  | awk -v b="\"$STEAM_BRANCH\"" '
      /"branches"/           { inb=1 }
      inb && $1==b           { f=1 }
      f && $1=="\"buildid\"" { gsub(/"/,"",$2); print $2; exit }' || true
}

update_server() {
  local beta_args=()
  [[ "$STEAM_BRANCH" != "public" ]] && beta_args=(-beta "$STEAM_BRANCH")

  for attempt in 1 2 3; do
    rc=0
    LogInfo "Installing vrising server into $SERVER_DIR"
    steamcmd \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$SERVER_DIR" \
        +login anonymous \
        +app_update "1829350" "${beta_args[@]}" validate \
        +quit || rc=$?
    (( rc == 0 )) && return 0
    LogWarn "SteamCMD failed (attempt $attempt/3, exit code $rc), retrying in 5 seconds..."
    tail -n 10 "$HOME/Steam/logs/stderr.txt" 2>/dev/null | sed 's/^/[steamcmd] /'
    sleep 5
  done
  LogError "SteamCMD failed 3 times"
  return 1
}

enable_disable_mods() {
  BEPINEX_MARKER="$SERVER_DIR/BepInEx/.installed-version"
  BEPINEX_VERSION="${BEPINEX_VERSION:-1.733.2}"
  ENABLE_MODS="${ENABLE_MODS:-false}"

  if [[ "$ENABLE_MODS" == "true" ]]; then
      if [[ -z "$BEPINEX_VERSION" && ! -d "$SERVER_DIR/BepInEx/core" ]]; then
          LogInfo "ENABLE_MODS=true but BEPINEX_VERSION is not set and BepInEx is not installed"
          exit 1
      fi

      INSTALLED=$(cat "$BEPINEX_MARKER" 2>/dev/null || echo none)
      if [[ -n "$BEPINEX_VERSION" && "$INSTALLED" != "$BEPINEX_VERSION" ]]; then
          LogInfo "Installing BepInExPack_V_Rising $BEPINEX_VERSION (was: $INSTALLED)"
          local bepinex_url="https://thunderstore.io/package/download/BepInEx/BepInExPack_V_Rising/${BEPINEX_VERSION}/"
          tmp=$(mktemp -d)
          curl -fsSL "$bepinex_url" -o "$tmp/bepinex.zip"
          unzip -q "$tmp/bepinex.zip" -d "$tmp/pack"

          src="$tmp/pack/BepInExPack_V_Rising"
          [[ -d "$src" ]] || src="$tmp/pack"
          cp -r "$src"/. "$SERVER_DIR"/
          mkdir -p "$SERVER_DIR/BepInEx/plugins" "$SERVER_DIR/BepInEx/config"
          echo "$BEPINEX_VERSION" > "$BEPINEX_MARKER"
          rm -rf "$tmp"
      fi

      export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winhttp=n,b"
      LogInfo "Mods enabled (BepInEx $(cat "$BEPINEX_MARKER" 2>/dev/null || echo unknown))"

      BEPINEX_CFG="$SERVER_DIR/BepInEx/config/BepInEx.cfg"
      mkdir -p "$(dirname "$BEPINEX_CFG")"
      if grep -q '^\[Logging.Console\]' "$BEPINEX_CFG" 2>/dev/null; then
          sed -i '/^\[Logging.Console\]/,/^\[/ s/^Enabled = .*/Enabled = false/' "$BEPINEX_CFG"
      else
          printf '\n[Logging.Console]\nEnabled = false\n' >> "$BEPINEX_CFG"
      fi
  else
    export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+$WINEDLLOVERRIDES;}winhttp=b"
    LogInfo "Mods disabled"
  fi
}

backup_server() {
  mkdir -p "$BACKUP_DIR"
    if [[ ! -d "$DATA_DIR/Saves/v4/$SAVE_NAME" ]]; then
    LogWarn "World '$SAVE_NAME' does not exist, skipping backup"
    return 0
  fi
  local name="$SAVE_NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
  LogInfo "Backing up current server to $name"
  tar -czf "$BACKUP_DIR/$name" -C "$DATA_DIR/Saves/v4/$SAVE_NAME" .
  ls -1t "$BACKUP_DIR"/$SAVE_NAME-*.tar.gz 2>/dev/null \
    | tail -n +$((BACKUPS_TO_KEEP + 1)) | xargs -r rm -f
}

shutdown() {
  LogInfo "Shutting server down in 1 minute, please wait for server to stop gracefully."
  rcon-call 'shutdown 1 "Shutting server down in 1 minute."'

  for ((i = 0; i < $SHUTDOWN_TIMEOUT; i++)); do
    kill -0 "$SERVER_PID" 2>/dev/null || break
    sleep 1
  done

  if pgrep -f 'VRisingServer\.exe' >/dev/null; then
    LogWarn "Server still running after ${SHUTDOWN_TIMEOUT}s, killing Wine"
    wineserver -k || true
  fi
  wait "$SERVER_PID" 2>/dev/null || true
  LogInfo "Stopped"
  exit 0
}