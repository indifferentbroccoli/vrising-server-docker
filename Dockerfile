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

ARG RCON_VERSION=0.10.3
ARG RCON_SHA256=6962a641ebf9a5957bd0cda1b8acf3e34a23686ae709f6c6a14ac3898521a5cc
RUN curl -fsSL \
    "https://github.com/gorcon/rcon-cli/releases/download/v${RCON_VERSION}/rcon-${RCON_VERSION}-amd64_linux.tar.gz" \
    -o /tmp/rcon.tar.gz && \
    echo "${RCON_SHA256}  /tmp/rcon.tar.gz" | sha256sum -c - && \
    tar --no-same-owner -xzf /tmp/rcon.tar.gz -C /tmp && \
    mv /tmp/rcon-${RCON_VERSION}-amd64_linux/rcon /usr/bin/rcon-cli && \
    rm -rf /tmp/rcon.tar.gz /tmp/rcon-${RCON_VERSION}-amd64_linux

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
    SERVER_DIR=/data/server-files \
    STEAM_BRANCH=public \
    UPDATE_ON_START=true \
    SERVER_NAME="Indifferent Broccoli V Rising Server" \
    SAVE_NAME=world1 \
    ENABLE_MODS=false \
    BEPINEX_VERSION=latest \
    RCON_PORT=25575

COPY ./scripts /home/steam/server/

COPY branding /branding

RUN mkdir -p /data/server-files && \
    chmod 777 /home/steam /data/server-files && \
    chmod +x /home/steam/server/*.sh

USER steam

WORKDIR /home/steam/server

HEALTHCHECK --start-period=5m \
            CMD pgrep "VRisingServer" > /dev/null || exit 1

VOLUME ["/data/server-files"]

EXPOSE 9876/udp 9877/udp 25575/tcp

ENTRYPOINT ["/home/steam/server/init.sh"]
