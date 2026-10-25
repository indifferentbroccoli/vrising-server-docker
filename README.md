<!-- markdownlint-disable-next-line -->
![marketing_assets_banner](https://github.com/user-attachments/assets/b8b4ae5c-06bb-46a7-8d94-903a04595036)
[![Discord](https://img.shields.io/discord/798321161082896395?style=for-the-badge&label=Discord&labelColor=5865F2&color=6aa84f)](https://discord.gg/indifferentbroccoli)

Game server hosting · Fast RAM · High-speed internet · Eat lag for breakfast

[Try our VRising server hosting free for 2 days!](https://indifferentbroccoli.com/v-rising-server-hosting)

# V Rising Dedicated Server Docker

A Docker container for running an V Rising dedicated server. The server binary is
Windows-only and runs via Wine.

## Server Requirements

| Resource | Minimum | Recommended | Maximum |
|----------|---------|-------------|---------|
| CPU      | 2 cores @ 3.2 GHz | 4 cores @ 3.2 GHz | 4 cores @ 3.2 GHz |
| RAM      | 4 GB    | 16 GB       | 32 GB   |
| Storage  | 5 GB SSD | 20 GB SSD | 40 GB SSD |

## How to use

Copy the `.env.example` file to `.env`, fill in your values, then use either `docker compose` or `docker run`.

### Docker Compose

```yaml
services:
  enshrouded:
    image: <image to be added>
    restart: unless-stopped
    container_name: vrising
    stop_grace_period: 30s
    ports:
      - "9876:9876/udp"
      - "9877:9877/udp"
      - "25575:25575/tcp"
    env_file:
      - .env
    volumes:
      - .\server:/data/server
      - .\saves:/data/saves             
      - .\config\bepinex:/data/config/bepinex
      - .\config\game:/data/config/game
      - .\plugins:/data/plugins
      - .\backups:/data/backups
```

```bash
docker compose up -d
```

### Docker Run

```bash
docker run -d \
    --restart unless-stopped \
    --name vrising \
    --stop-timeout 60 \
    -p 9876:9876/udp \
    -p 9877:9877/udp \
    -p 25575:25575/tcp \
    --env-file .env \
    -v .\server:/data/server \
    -v .\saves:/data/saves  \
    -v .\config\bepinex:/data/config/bepinex \
    -v .\config\game:/data/config/game \
    -v .\plugins:/data/plugins \
    -v .\backups:/data/backups \
    <image to be added>
```

## Environment Variables

| Variable | Default | Info |
|----------|---------|------|
| SERVER_NAME | Indifferent Broccoli V Rising Server | Display name of the server |
| SAVE_NAME | world1 | Name of the Save Folder |
| UPDATE_ON_START | true | Download and validate server files on every startup. Set to `false` to skip. |
| STEAM_BRANCH | public | Can be configured to public or beta branches for new updates. |
| BACKUPS_TO_KEEP | 2 | Number of startup backups to keep. |
| ENABLE_MODS | false | `true/false` Install the BepInEx plugin for mods. |
| BEPINEX_VERSION | 1.733.2 | `Default` 1.733.2 which is the current latest version of BepInEx installed. |
| RCON_PASSWORD | CHANGEME | Password generated randomly on startup unless a specific password is provided. |


## About

This is a Dockerized V Rising dedicated server maintained by [indifferent broccoli](https://indifferentbroccoli.com/). We offer [managed V Rising server hosting](https://indifferentbroccoli.com/v-rising-server-hosting) if you'd rather not self-host.


