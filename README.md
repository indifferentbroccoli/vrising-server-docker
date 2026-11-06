<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![GitHub License](https://img.shields.io/github/license/indifferentbroccoli/vrising-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/vrising-server-docker/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/indifferentbroccoli/vrising-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/vrising-server-docker/releases)
[![GitHub Repo stars](https://img.shields.io/github/stars/indifferentbroccoli/vrising-server-docker?style=for-the-badge&color=6aa84f)](https://github.com/indifferentbroccoli/vrising-server-docker)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)
[![Docker Pulls](https://img.shields.io/docker/pulls/indifferentbroccoli/vrising-server-docker?style=for-the-badge&color=6aa84f)](https://hub.docker.com/r/indifferentbroccoli/vrising-server-docker)

Game server hosting

Fast RAM, high-speed internet

Eat lag for breakfast

[Try our V Rising server hosting free for 2 days!](https://indifferentbroccoli.com/v-rising-server-hosting)

## V Rising Dedicated Server Docker

A Docker container for running a V Rising dedicated server. Server files are downloaded with
[DepotDownloader](https://github.com/SteamRE/DepotDownloader). The server binary is
Windows-only and runs via Wine.

## Server Requirements

| Resource | Minimum           | Recommended       |
|----------|-------------------|-------------------|
| CPU      | 2 cores @ 3.2 GHz | 4 cores @ 3.2 GHz |
| RAM      | 4GB               | 16GB              |
| Storage  | 5GB SSD           | 20GB SSD          |

## How to use

Copy the .env.example file to a new file called .env. Then use either `docker compose` or `docker run`

> [!IMPORTANT]
> The server runs as user and group 1000, not root. The folder you mount must be owned by that user, for example `sudo chown -R 1000:1000 ./server-files`.
> To use a different id, set `user: "1001:1001"` in docker compose or `--user 1001:1001` with docker run, and give your folder to that id instead.

### Docker compose

```yaml
services:
  vrising:
    image: indifferentbroccoli/vrising-server-docker
    restart: unless-stopped
    container_name: vrising
    stop_grace_period: 90s
    tty: true
    ports:
      - 9876:9876/udp
      - 9877:9877/udp
      - 25575:25575/tcp
    env_file:
      - .env
    volumes:
      - ./server-files:/data/server-files
```

Then run:

```bash
docker compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name vrising \
    --stop-timeout 90 \
    -t \
    -p 9876:9876/udp \
    -p 9877:9877/udp \
    -p 25575:25575/tcp \
    --env-file .env \
    -v ./server-files:/data/server-files \
    indifferentbroccoli/vrising-server-docker
```

## Environment Variables

| Variable          | Default                              | Info                                                                              |
|-------------------|--------------------------------------|-----------------------------------------------------------------------------------|
| SERVER_NAME       | Indifferent Broccoli V Rising Server | Name shown in the server browser                                                  |
| SAVE_NAME         | world1                               | Name of the world save folder                                                     |
| UPDATE_ON_START   | true                                 | Download and validate server files on every startup. Set to `false` to skip      |
| STEAM_BRANCH      | public                               | Steam branch to install                                                           |
| ENABLE_MODS       | false                                | Install BepInEx so the server can load mods                                       |
| BEPINEX_VERSION   | latest                               | BepInEx version to install. `latest` updates on startup, or pin one, e.g. `1.733.2` |
| RCON_PASSWORD     |                                      | RCON password. If empty, one is generated and saved in `data/Settings/ServerHostSettings.json` |
| RCON_PORT         | 25575                                | RCON port                                                                         |

## Port Forwarding

Forward the following ports to your server:

* `9876/udp` - Game port
* `9877/udp` - Query port
* `25575/tcp` - RCON port (only if you use RCON)

## Support

For issues and questions:
* GitHub Issues: [Report an issue](https://github.com/indifferentbroccoli/vrising-server-docker/issues)
* Game Server Hosting: [indifferentbroccoli.com](https://indifferentbroccoli.com)
