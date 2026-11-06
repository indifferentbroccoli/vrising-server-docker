#!/bin/bash

APP_ID=1829350
DATA_DIR=$SERVER_DIR/data
CONFIG_DIR=$DATA_DIR/Settings
LOG_DIR=$SERVER_DIR/logs
LOG_FILE=$LOG_DIR/VRisingServer.log
RCON_CONFIG=$HOME/rcon.yml

LogInfo()    { printf '%s\n' "$1"; }
LogWarn()    { printf '\033[1;33m%s\033[0m\n' "$1"; }
LogError()   { printf '\033[1;31m%s\033[0m\n' "$1"; }
LogSuccess() { printf '\033[1;32m%s\033[0m\n' "$1"; }
LogAction()  { printf '\033[1;36m==== %s ====\033[0m\n' "$1"; }

server_is_installed() {
  [ -f "$SERVER_DIR/VRisingServer.exe" ]
}

install_server() {
  LogAction "Installing server (branch: $STEAM_BRANCH)"

  local args=(-app "$APP_ID" -os windows -osarch 64 -dir "$SERVER_DIR" -validate)

  if [ "$STEAM_BRANCH" != "public" ]; then
    args+=(-beta "$STEAM_BRANCH")
  fi

  if ! /depotdownloader/DepotDownloader "${args[@]}"; then
    LogError "Server install failed"
    return 1
  fi

  LogSuccess "Server installed"
}

rotate_log() {
  mkdir -p "$LOG_DIR"
  if [ -s "$LOG_FILE" ]; then
    mv "$LOG_FILE" "$LOG_DIR/VRisingServer-$(date +%Y%m%d-%H%M%S).log"
  fi
}

seed_settings() {
  local defaults=$SERVER_DIR/VRisingServer_Data/StreamingAssets/Settings
  mkdir -p "$CONFIG_DIR"
  for file in ServerHostSettings.json ServerGameSettings.json; do
    if [ ! -f "$CONFIG_DIR/$file" ] && [ -f "$defaults/$file" ]; then
      LogInfo "Creating default $file"
      cp "$defaults/$file" "$CONFIG_DIR/$file"
    fi
  done
}

configure_rcon() {
  local file=$CONFIG_DIR/ServerHostSettings.json
  local tmp

  if [ -z "$RCON_PASSWORD" ]; then
    RCON_PASSWORD=$(jq -r '.Rcon.Password // empty' "$file")
  fi
  if [ -z "$RCON_PASSWORD" ]; then
    RCON_PASSWORD=$(head -c 32 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)
    LogInfo "No RCON_PASSWORD set, generated one and saved it in data/Settings/ServerHostSettings.json"
  fi

  tmp=$(mktemp "$file.XXXX")
  jq --arg pw "$RCON_PASSWORD" --arg port "$RCON_PORT" \
    '.Rcon.Enabled = true | .Rcon.Password = $pw | .Rcon.Port = ($port | tonumber)' \
    "$file" > "$tmp" && mv "$tmp" "$file"

  cat > "$RCON_CONFIG" <<EOF
default:
  address: "127.0.0.1:$RCON_PORT"
  password: "$RCON_PASSWORD"
EOF
  LogInfo "RCON enabled on port $RCON_PORT"
}

latest_bepinex_version() {
  curl -fsSL https://thunderstore.io/api/experimental/package/BepInEx/BepInExPack_V_Rising/ \
    | jq -r '.latest.version_number'
}

install_bepinex() {
  local marker=$SERVER_DIR/BepInEx/.installed-version
  local installed
  installed=$(cat "$marker" 2>/dev/null)

  if [ -z "$BEPINEX_VERSION" ] || [ "$BEPINEX_VERSION" = "latest" ]; then
    BEPINEX_VERSION=$(latest_bepinex_version)
    if [ -z "$BEPINEX_VERSION" ] || [ "$BEPINEX_VERSION" = "null" ]; then
      if [ -n "$installed" ]; then
        LogWarn "Could not check BepInEx for updates, keeping the installed version"
        BEPINEX_VERSION=$installed
        return
      fi
      LogError "Could not find the latest BepInEx version"
      exit 1
    fi
  fi

  if [ "$installed" = "$BEPINEX_VERSION" ]; then
    return
  fi

  LogInfo "Installing BepInEx $BEPINEX_VERSION"
  local tmp
  tmp=$(mktemp -d)
  if ! curl -fsSL "https://thunderstore.io/package/download/BepInEx/BepInExPack_V_Rising/$BEPINEX_VERSION/" -o "$tmp/bepinex.zip" \
    || ! unzip -q "$tmp/bepinex.zip" -d "$tmp/pack"; then
    rm -rf "$tmp"
    LogError "Could not download BepInEx $BEPINEX_VERSION"
    exit 1
  fi

  local src=$tmp/pack/BepInExPack_V_Rising
  [ -d "$src" ] || src=$tmp/pack
  cp -r "$src"/. "$SERVER_DIR"/
  mkdir -p "$SERVER_DIR/BepInEx/plugins" "$SERVER_DIR/BepInEx/config"
  echo "$BEPINEX_VERSION" > "$marker"
  rm -rf "$tmp"
}

configure_mods() {
  if [ "$ENABLE_MODS" != "true" ]; then
    export WINEDLLOVERRIDES="winhttp=b"
    return
  fi

  LogAction "Enabling mods"
  install_bepinex
  export WINEDLLOVERRIDES="winhttp=n,b"
  LogSuccess "Mods enabled (BepInEx $BEPINEX_VERSION)"
}
