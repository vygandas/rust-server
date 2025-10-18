# Rust Server Dockerized - aux01 Staging Branch

A Dockerized Rust dedicated server configured for the **aux01 staging branch** - perfect for testing new features and HDRP (High Definition Render Pipeline) updates before they hit the main branch.

## Blood & Fire Clan - Testing Server

This is a fully configured Dockerized version of a Rust game server running the aux01 staging branch for testing purposes.

## What is aux01?

The **aux01 branch** is Rust's staging/testing branch that includes:
- 🎮 HDRP (High Definition Render Pipeline) features
- 🔧 Experimental features before main branch release
- 🧪 Latest backported updates for testing
- ⚡ New performance optimizations

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/yourusername/rust-server-bnf.git
   cd rust-server-bnf
   ```

2. **Configure your server:**
   ```bash
   cp .env.example .env
   nano .env  # or your preferred editor

   # CRITICAL: Change these values:
   # - RUST_RCON_PASSWORD (use a strong password)
   # - RWA_USERNAME and RWA_PASSWORD (for web RCON)
   # - RUST_SERVER_SEED (for unique map generation)
   ```

3. **Build the aux01 server image:**
   ```bash
   docker-compose build --no-cache
   ```

4. **Start the server:**
   ```bash
   docker-compose up -d
   ```

5. **Monitor server startup (aux01 takes ~10-15 minutes):**
   ```bash
   docker-compose logs -f rust-server
   ```

6. **Access Web RCON (optional):**
   ```
   http://your-server-ip:4326
   ```

## Server Management

### Starting/Stopping
```bash
# Start server
docker-compose up -d

# Stop server
docker-compose down

# Restart server
docker-compose restart
```

### Accessing Console
```bash
# View logs
docker-compose logs -f rust-server

# Execute RCON commands (requires rcon-cli)
docker exec -it rust-server rcon-cli
```

### Updating Server (aux01 Branch)
The server automatically updates to the latest aux01 branch on startup. To force an update:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

To disable auto-updates, set in your `.env`:
```bash
RUST_UPDATE_ON_START=false
```

### Wiping Server
```bash
# Full wipe (map + blueprints)
docker-compose down
rm -rf ./server_data/*
docker-compose up -d
```

## Configuration

Configuration is managed through environment variables in `.env` file or `docker-compose.yml`:

### Key Settings for aux01

- **Branch**: `-beta aux01` (configured by default)
- **Server Name**: Custom name for your staging server
- **Max Players**: 100 (recommended for aux01 testing)
- **World Size**: 1000-6000 (3500 recommended for staging)
- **Seed**: Change for different map generation
- **RCON Password**: **MUST CHANGE** - Use a strong password
- **Tickrate**: 30 (maximum for best performance)
- **Oxide/Carbon**: Optional modding frameworks

### Performance Tuning for aux01

The aux01 branch may require more resources:
- **RAM**: 16GB recommended (8GB minimum)
- **CPU**: 4 cores recommended (2 minimum)
- **Storage**: 30GB+ for server files and world data

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 28015 | UDP/TCP | Game traffic (main) |
| 28017 | UDP | Query port (server browser) |
| 28016 | TCP | RCON (Remote Console) |
| 28080 | TCP | Web RCON interface |
| 28082 | TCP | Rust+ Companion App |
| 4326 | TCP | RCON Web UI (optional) |
| 4327 | TCP | RCON WebSocket (optional) |

## System Requirements

- **RAM**: Minimum 8GB, recommended 16GB+
- **Storage**: 20GB minimum for server files
- **CPU**: 2+ cores recommended
- **OS**: Linux (Ubuntu/Debian preferred)

## Troubleshooting

### Server won't start
- Check logs: `docker-compose logs rust-server`
- Ensure ports aren't already in use
- Verify sufficient disk space

### Can't connect to server
- Ensure firewall allows UDP 28015
- Check server is fully started (can take 5-10 minutes)
- Verify server is updated to latest version

### High memory usage
- Adjust `mem_limit` in docker-compose.yml
- Consider reducing world size or max players

## Backup

Regular backups are recommended:
```bash
# Backup server data
tar -czf backup-$(date +%Y%m%d).tar.gz ./server_data/

# Restore from backup
tar -xzf backup-20240101.tar.gz
```

## aux01 Specific Notes

### Joining the Server
Players need to be on the Rust Staging Branch to connect:
1. In Steam, right-click "Rust - Staging Branch"
2. Properties → Betas → Select "aux01 - backport"
3. Wait for download to complete
4. Launch Rust from "Rust - Staging Branch"

### Known aux01 Considerations
- **Longer startup times**: aux01 servers take 10-15 minutes to fully initialize
- **Higher resource usage**: HDRP features require more RAM/CPU
- **Experimental features**: May encounter bugs not present in main branch
- **Frequent updates**: aux01 receives updates more frequently than main
- **Wipe schedule**: May differ from main branch wipe schedule

### Enabling Mods (Oxide/Carbon)
To enable Oxide for plugins:
```bash
# In your .env file:
RUST_OXIDE_ENABLED=true
```

To enable Carbon (alternative to Oxide):
```bash
# In your .env file:
RUST_CARBON_ENABLED=true
```

## Advanced Configuration

### Custom Maps
Place custom map files in `./custom_maps/` and set:
```bash
RUST_SERVER_LEVEL=YourMapName
RUST_SERVER_LEVELURL=http://your-map-url.com/map.map
```

### Server Tags
Help players find your server:
```bash
RUST_SERVER_TAGS=staging,aux01,testing,modded,10x
```

## License

This Docker setup is provided as-is. Rust is a trademark of Facepunch Studios Ltd.