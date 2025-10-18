#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Rust Dedicated Server (aux01 Staging Branch) ===${NC}"
echo -e "${YELLOW}Starting server initialization...${NC}"

# Set default values for environment variables
export RUST_BRANCH="${RUST_BRANCH:--beta aux01-staging}"
export RUST_BRANCH_PASSWORD="${RUST_BRANCH_PASSWORD:-}"
export RUST_UPDATE_ON_START="${RUST_UPDATE_ON_START:-true}"
export RUST_OXIDE_ENABLED="${RUST_OXIDE_ENABLED:-false}"
export RUST_CARBON_ENABLED="${RUST_CARBON_ENABLED:-false}"

# Update server on startup if enabled
if [ "$RUST_UPDATE_ON_START" = "true" ]; then
    echo -e "${YELLOW}Checking for server updates (aux01 branch)...${NC}"
    /home/steam/steamcmd/steamcmd.sh \
        +force_install_dir /home/steam/rust_server \
        +login anonymous \
        +app_update 258550 ${RUST_BRANCH} ${RUST_BRANCH_PASSWORD} validate \
        +quit

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Server update completed successfully${NC}"
    else
        echo -e "${RED}Server update failed, continuing with existing version${NC}"
    fi
else
    echo -e "${YELLOW}Skipping server update (RUST_UPDATE_ON_START=false)${NC}"
fi

# Install Oxide if enabled
if [ "$RUST_OXIDE_ENABLED" = "true" ] && [ ! -f "/home/steam/rust_server/RustDedicated_Data/Managed/Oxide.Core.dll" ]; then
    echo -e "${YELLOW}Installing Oxide/uMod...${NC}"
    cd /home/steam/rust_server
    curl -L https://umod.org/games/rust/download/develop -o oxide.zip
    unzip -o oxide.zip
    rm oxide.zip
    echo -e "${GREEN}Oxide/uMod installed${NC}"
fi

# Install Carbon if enabled (alternative modding framework)
if [ "$RUST_CARBON_ENABLED" = "true" ] && [ ! -f "/home/steam/rust_server/carbon/managed/Carbon.dll" ]; then
    echo -e "${YELLOW}Installing Carbon...${NC}"
    cd /home/steam/rust_server
    curl -L https://github.com/CarbonCommunity/Carbon/releases/latest/download/Carbon.Linux.Release.tar.gz -o carbon.tar.gz
    tar -xzf carbon.tar.gz
    rm carbon.tar.gz
    echo -e "${GREEN}Carbon installed${NC}"
fi

# Set library path for plugins
export LD_LIBRARY_PATH=/home/steam/rust_server:/home/steam/rust_server/RustDedicated_Data/Plugins/x86_64:$LD_LIBRARY_PATH

# Performance optimizations
export MALLOC_CHECK_=0
export MALLOC_MMAP_THRESHOLD_=131072
export MALLOC_TRIM_THRESHOLD_=131072
export MALLOC_TOP_PAD_=131072
export MALLOC_MMAP_MAX_=65536

# Construct server arguments
SERVER_ARGS="-batchmode -nographics -silent-crashes"

# Core server settings
SERVER_ARGS="$SERVER_ARGS +server.ip ${RUST_SERVER_IP:-0.0.0.0}"
SERVER_ARGS="$SERVER_ARGS +server.port ${RUST_SERVER_PORT:-28015}"
SERVER_ARGS="$SERVER_ARGS +server.queryport ${RUST_QUERY_PORT:-28017}"
SERVER_ARGS="$SERVER_ARGS +server.tickrate ${RUST_SERVER_TICKRATE:-30}"

# RCON settings
SERVER_ARGS="$SERVER_ARGS +rcon.ip ${RUST_RCON_IP:-0.0.0.0}"
SERVER_ARGS="$SERVER_ARGS +rcon.port ${RUST_RCON_PORT:-28016}"
SERVER_ARGS="$SERVER_ARGS +rcon.password \"${RUST_RCON_PASSWORD:-changeme}\""
SERVER_ARGS="$SERVER_ARGS +rcon.web ${RUST_RCON_WEB:-1}"

# Server identity and metadata
SERVER_ARGS="$SERVER_ARGS +server.hostname \"${RUST_SERVER_HOSTNAME:-Rust aux01 Staging Server}\""
SERVER_ARGS="$SERVER_ARGS +server.description \"${RUST_SERVER_DESCRIPTION:-Testing aux01 staging branch features}\""
SERVER_ARGS="$SERVER_ARGS +server.url \"${RUST_SERVER_URL:-}\""
SERVER_ARGS="$SERVER_ARGS +server.headerimage \"${RUST_SERVER_BANNER:-}\""
SERVER_ARGS="$SERVER_ARGS +server.logoimage \"${RUST_SERVER_LOGO:-}\""

# Game settings
SERVER_ARGS="$SERVER_ARGS +server.maxplayers ${RUST_SERVER_MAXPLAYERS:-50}"
SERVER_ARGS="$SERVER_ARGS +server.worldsize ${RUST_SERVER_WORLDSIZE:-3000}"
SERVER_ARGS="$SERVER_ARGS +server.seed ${RUST_SERVER_SEED:-12345}"
SERVER_ARGS="$SERVER_ARGS +server.identity \"${RUST_SERVER_IDENTITY:-aux01_test}\""
SERVER_ARGS="$SERVER_ARGS +server.level \"${RUST_SERVER_LEVEL:-Procedural Map}\""

# Performance and gameplay settings
SERVER_ARGS="$SERVER_ARGS +server.saveinterval ${RUST_SERVER_SAVE_INTERVAL:-300}"
SERVER_ARGS="$SERVER_ARGS +decay.tick ${RUST_DECAY_TICK:-300}"
SERVER_ARGS="$SERVER_ARGS +decay.scale ${RUST_DECAY_SCALE:-1}"
SERVER_ARGS="$SERVER_ARGS +server.globalchat ${RUST_SERVER_GLOBALCHAT:-true}"
SERVER_ARGS="$SERVER_ARGS +server.pve ${RUST_SERVER_PVE:-false}"
SERVER_ARGS="$SERVER_ARGS +server.stability ${RUST_SERVER_STABILITY:-true}"

# Rust+ Companion app
SERVER_ARGS="$SERVER_ARGS +app.port ${RUST_APP_PORT:-28082}"
SERVER_ARGS="$SERVER_ARGS +app.publicip \"${RUST_APP_PUBLICIP:-}\""

# Anti-cheat settings
SERVER_ARGS="$SERVER_ARGS +server.secure ${RUST_SERVER_SECURE:-true}"
SERVER_ARGS="$SERVER_ARGS +server.encryption ${RUST_SERVER_ENCRYPTION:-2}"
SERVER_ARGS="$SERVER_ARGS +server.anticheatlog ${RUST_ANTICHEAT_LOG:-1}"

# Logging
SERVER_ARGS="$SERVER_ARGS -logfile \"${RUST_LOG_FILE:-/dev/stdout}\""

# Optional: Tags for server browser
if [ -n "${RUST_SERVER_TAGS}" ]; then
    SERVER_ARGS="$SERVER_ARGS +server.tags \"${RUST_SERVER_TAGS}\""
fi

# Optional: Custom map URL
if [ -n "${RUST_SERVER_LEVELURL}" ]; then
    SERVER_ARGS="$SERVER_ARGS +server.levelurl \"${RUST_SERVER_LEVELURL}\""
fi

echo -e "${GREEN}Starting Rust Dedicated Server (aux01 staging branch)...${NC}"
echo -e "${YELLOW}Server Identity: ${RUST_SERVER_IDENTITY:-aux01_test}${NC}"
echo -e "${YELLOW}Server Name: ${RUST_SERVER_HOSTNAME:-Rust aux01 Staging Server}${NC}"
echo -e "${YELLOW}Max Players: ${RUST_SERVER_MAXPLAYERS:-50}${NC}"
echo -e "${YELLOW}World Size: ${RUST_SERVER_WORLDSIZE:-3000}${NC}"
echo -e "${YELLOW}Server Seed: ${RUST_SERVER_SEED:-12345}${NC}"

# Bootstrap admin users from env (writes to users.cfg before launch)
if [ -n "${RUST_OWNER_ID}" ]; then
    IDENTITY_DIR="/home/steam/rust_server/server/${RUST_SERVER_IDENTITY:-aux01_test}/cfg"
    USERS_CFG="${IDENTITY_DIR}/users.cfg"
    mkdir -p "${IDENTITY_DIR}"
    if [ -f "${USERS_CFG}" ]; then
        sed -i "/^ownerid ${RUST_OWNER_ID}\\b/d" "${USERS_CFG}"
    fi
    echo "ownerid ${RUST_OWNER_ID} \"${RUST_OWNER_NAME:-${RUST_OWNER_ID}}\" \"${RUST_OWNER_REASON:-Bootstrap}\"" >> "${USERS_CFG}"
fi

# Start the server
cd /home/steam/rust_server
exec ./RustDedicated $SERVER_ARGS
