FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including additional libraries for better compatibility
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    lib32gcc-s1 \
    lib32stdc++6 \
    libsdl2-2.0-0 \
    ca-certificates \
    locales \
    netcat \
    procps \
    unzip \
    xz-utils \
    lib32z1 \
    libc6-i386 \
    libgcc1 \
    libstdc++6 \
    libncurses5 \
    libsdl1.2debian \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create steam user with specific UID/GID for better permission handling
RUN groupadd -g 1000 steam && \
    useradd -m -u 1000 -g steam -s /bin/bash steam

# Switch to steam user
USER steam
WORKDIR /home/steam

# Download and extract SteamCMD
RUN mkdir -p steamcmd && \
    cd steamcmd && \
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz && \
    tar -xzf steamcmd_linux.tar.gz && \
    rm steamcmd_linux.tar.gz

# Create necessary directories
RUN mkdir -p rust_server server_data

# Install Rust Dedicated Server with aux01 staging branch
# Using build args to allow flexibility
ARG RUST_BRANCH="-beta aux01"
ARG RUST_BRANCH_PASSWORD=""

# Initial installation with staging branch
RUN /home/steam/steamcmd/steamcmd.sh \
    +force_install_dir /home/steam/rust_server \
    +login anonymous \
    +app_update 258550 ${RUST_BRANCH} ${RUST_BRANCH_PASSWORD} validate \
    +quit

# Create necessary server directories
RUN mkdir -p /home/steam/rust_server/server_data \
    /home/steam/rust_server/oxide \
    /home/steam/rust_server/carbon

# Expose necessary ports
# Game port (UDP/TCP)
EXPOSE 28015/udp
EXPOSE 28015/tcp
# Query port (UDP)
EXPOSE 28017/udp
# RCON port (TCP)
EXPOSE 28016/tcp
# Rust+ app port (TCP)
EXPOSE 28082/tcp
# Web RCON (TCP)
EXPOSE 28080/tcp

# Set working directory
WORKDIR /home/steam/rust_server

# Create an improved startup script with better error handling and aux01 support
RUN cat > /home/steam/start_server.sh << 'EOF'
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
export RUST_BRANCH="${RUST_BRANCH:--beta aux01}"
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
SERVER_ARGS="$SERVER_ARGS -logfile \"${RUST_LOG_FILE:-/home/steam/rust_server/server_data/server.log}\""

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

# Start the server
exec ./RustDedicated $SERVER_ARGS
EOF

RUN chmod +x /home/steam/start_server.sh

# Create a healthcheck script
RUN cat > /home/steam/healthcheck.sh << 'EOF'
#!/bin/bash
# Check if RustDedicated process is running
pgrep -f RustDedicated > /dev/null 2>&1
if [ $? -eq 0 ]; then
    # Optional: Check if RCON port is responding
    if [ -n "${RUST_RCON_PORT}" ]; then
        nc -z localhost ${RUST_RCON_PORT:-28016} > /dev/null 2>&1
        exit $?
    fi
    exit 0
else
    exit 1
fi
EOF

RUN chmod +x /home/steam/healthcheck.sh

# Define volumes for persistent data
VOLUME ["/home/steam/rust_server/server_data"]
VOLUME ["/home/steam/rust_server/oxide"]
VOLUME ["/home/steam/rust_server/carbon"]

# Add healthcheck
HEALTHCHECK --interval=5m --timeout=10s --start-period=10m --retries=3 \
    CMD ["/home/steam/healthcheck.sh"]

# Set the entrypoint
ENTRYPOINT ["/home/steam/start_server.sh"]