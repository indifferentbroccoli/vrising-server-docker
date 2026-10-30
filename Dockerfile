FROM golang:1.23.1-alpine AS rcon-cli_builder

ARG RCON_VERSION="0.10.3"
ARG RCON_TGZ_SHA1SUM=33ee8077e66bea6ee097db4d9c923b5ed390d583

WORKDIR /build

# install rcon
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ENV CGO_ENABLED=0
RUN wget -q https://github.com/gorcon/rcon-cli/archive/refs/tags/v${RCON_VERSION}.tar.gz -O rcon.tar.gz \
    && echo "${RCON_TGZ_SHA1SUM}" rcon.tar.gz | sha1sum -c - \
    && tar -xzvf rcon.tar.gz \
    && rm rcon.tar.gz \
    && mv rcon-cli-${RCON_VERSION}/* ./ \
    && rm -rf rcon-cli-${RCON_VERSION} \
    && go build -v ./cmd/gorcon

FROM debian:bookworm-slim

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/v-rising-server-docker" \
      github="https://github.com/indifferentbroccoli/v-rising-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/v-rising-server-docker"

ENV DEBIAN_FRONTEND=noninteractive \
    WINEARCH=win64 \
    WINEPREFIX=/home/steam/.wine \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES="mscoree,mshtml="

COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon-cli

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg unzip procps \
        lib32gcc-s1 lib32stdc++6 libgnutls30 jq \
    && apt-get install -y --no-install-recommends xvfb xauth \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian/ bookworm main" \
        > /etc/apt/sources.list.d/winehq.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends winehq-stable \
    && apt-get purge -y gnupg && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash steam \
    && mkdir -p /opt/steamcmd /data/server-files \
    && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar -xz -C /opt/steamcmd \
    && chown -R steam:steam /opt/steamcmd /data

COPY --chown=steam:steam ./scripts /home/steam/server/
RUN chmod +x /home/steam/server/*.sh

COPY branding /branding

RUN mkdir -p /tmp/runtime-steam \
 && chown steam:steam /tmp/runtime-steam \
 && chmod 700 /tmp/runtime-steam

USER steam

RUN /opt/steamcmd/steamcmd.sh +quit || true \
    && wineboot --init && wineserver -w

ENV SERVER_DIR=/data/server-files \
    STEAM_BRANCH=public \
    SHUTDOWN_TIMEOUT=90

WORKDIR /data/server-files

HEALTHCHECK --start-period=5m \
    CMD pgrep "VRisingServer" > /dev/null || exit 1

VOLUME ["/data/server-files"]
EXPOSE 9876/udp 9877/udp 25575/tcp

ENTRYPOINT ["/usr/bin/bash", "--", "/home/steam/server/init.sh"]