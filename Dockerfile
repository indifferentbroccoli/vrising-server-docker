# BUILD RCON-CLI
FROM golang:1.23.1-alpine AS rcon-cli_builder

ARG RCON_VERSION="0.10.3"
ARG RCON_TGZ_SHA1SUM=33ee8077e66bea6ee097db4d9c923b5ed390d583

WORKDIR /build

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ENV CGO_ENABLED=0
RUN wget -q https://github.com/gorcon/rcon-cli/archive/refs/tags/v${RCON_VERSION}.tar.gz -O rcon.tar.gz \
    && echo "${RCON_TGZ_SHA1SUM}" rcon.tar.gz | sha1sum -c - \
    && tar -xzf rcon.tar.gz \
    && mv rcon-cli-${RCON_VERSION}/* ./ \
    && go build -v ./cmd/gorcon

# BUILD THE SERVER IMAGE
FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Wine (the server is Windows-only) and a virtual display for it
RUN dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        unzip \
        procps \
        jq \
        libicu72 \
        xvfb \
        xauth \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
        > /etc/apt/sources.list.d/winehq.list \
    && apt-get update && apt-get install -y --no-install-recommends winehq-stable \
    && apt-get purge -y gnupg && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download DepotDownloader
ARG DEPOT_DOWNLOADER_VERSION=3.4.0
RUN curl -fsSL \
    "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/DepotDownloader-linux-x64.zip" \
    -o /tmp/dd.zip && \
    mkdir -p /depotdownloader && \
    unzip /tmp/dd.zip DepotDownloader -d /depotdownloader && \
    chmod +x /depotdownloader/DepotDownloader && \
    rm /tmp/dd.zip

COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon-cli

RUN useradd -m -u 1000 -s /bin/bash steam

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/vrising-server-docker" \
      github="https://github.com/indifferentbroccoli/vrising-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/vrising-server-docker"

ENV HOME=/home/steam \
    WINEARCH=win64 \
    WINEPREFIX=/home/steam/.wine \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    XDG_RUNTIME_DIR=/tmp/runtime-steam \
    SERVER_DIR=/data/server-files \
    STEAM_BRANCH=public \
    UPDATE_ON_START=true \
    SERVER_NAME="Indifferent Broccoli V Rising Server" \
    SAVE_NAME=world1 \
    ENABLE_MODS=false \
    BEPINEX_VERSION=latest \
    RCON_PORT=25575 \
    SHUTDOWN_TIMEOUT=90

COPY ./scripts /home/steam/server/

COPY branding /branding

RUN mkdir -p /data/server-files /tmp/runtime-steam && \
    chown steam:steam /data/server-files /tmp/runtime-steam && \
    chmod 700 /tmp/runtime-steam && \
    chmod +x /home/steam/server/*.sh

USER steam

RUN wineboot --init && wineserver -w

WORKDIR /home/steam/server

HEALTHCHECK --start-period=5m \
            CMD pgrep "VRisingServer" > /dev/null || exit 1

VOLUME ["/data/server-files"]

EXPOSE 9876/udp 9877/udp 25575/tcp

ENTRYPOINT ["/home/steam/server/init.sh"]
