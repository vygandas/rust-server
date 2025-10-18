# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Dockerized Rust game server setup for running a dedicated Rust (the survival game) server using SteamCMD.

## Key Ports

- **28015**: Game port (UDP) - Main game traffic
- **28016**: RCON port (TCP) - Remote console administration
- **28082**: Rust+ app port (TCP) - For Rust+ companion app

## Common Commands

### Docker Operations
```bash
# Build the Docker image
docker build -t rust-game-server .

# Run with docker-compose (recommended)
docker-compose up -d

# Stop the server
docker-compose down

# View server logs
docker-compose logs -f rust-server

# Access server console
docker exec -it rust-server rcon-cli

# Force wipe the server (removes map and player data)
docker-compose down
rm -rf ./server_data/server/my_server_identity/*
docker-compose up -d
```

### Server Management
```bash
# Connect to RCON (after installing rcon-cli)
rcon -H localhost -p YOUR_RCON_PASSWORD

# Update server (rebuild image)
docker-compose down
docker build --no-cache -t rust-game-server .
docker-compose up -d
```

## Architecture

### Docker Setup
- **Base Image**: Uses Ubuntu/Debian with SteamCMD to download and run the Rust dedicated server
- **Volume Mounts**: Server data persisted in `./server_data` to maintain world saves, player data, and configurations
- **Environment Variables**: Server configuration controlled via environment variables in docker-compose.yml

### Directory Structure
```
/
├── Dockerfile                 # Main container definition with SteamCMD and server setup
├── docker-compose.yml         # Orchestration with environment variables and volumes
├── server_data/              # Persistent volume mount for server files
│   └── server/               # Rust server installation and data
└── scripts/                  # Helper scripts for server management
    └── start_server.sh       # Entry point script for the container
```

### Server Configuration
The server is configured through environment variables passed in docker-compose.yml:
- `RUST_SERVER_IDENTITY`: Server identity folder name
- `RUST_SERVER_SEED`: World generation seed
- `RUST_SERVER_WORLDSIZE`: Map size (1000-6000)
- `RUST_SERVER_MAXPLAYERS`: Maximum concurrent players
- `RUST_SERVER_HOSTNAME`: Server name shown in server browser
- `RUST_SERVER_DESCRIPTION`: Server description
- `RUST_RCON_PASSWORD`: RCON password for remote administration
- `RUST_SERVER_SAVE_INTERVAL`: Auto-save interval in seconds

### SteamCMD Integration
The Dockerfile handles:
1. Installing SteamCMD dependencies
2. Downloading Rust Dedicated Server (App ID: 258550)
3. Configuring server startup parameters
4. Managing server updates through image rebuilds

## Important Considerations

- **Server Wipes**: Rust servers typically wipe on a schedule. Map wipes clear the world, blueprint wipes clear learned items.
- **Oxide/uMod**: For plugin support, Oxide needs to be installed after SteamCMD downloads the server
- **Performance**: Allocate at least 8GB RAM for small servers, 16GB+ for larger populations
- **Backups**: Implement regular backups of `./server_data/server/my_server_identity/` for world saves
- **Updates**: Rust forces weekly updates (Thursdays). Server must be updated to allow players to connect.