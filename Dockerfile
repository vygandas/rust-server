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

# Install Rust Dedicated Server with aux01-staging branch
# Using build args to allow flexibility
# Options: "", "-beta staging", "-beta prerelease", "-beta aux01-staging"
ARG RUST_BRANCH="-beta aux01-staging"
ARG RUST_BRANCH_PASSWORD=""

# Initial installation with aux01-staging branch
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

# Copy scripts
COPY --chown=steam:steam scripts/start_server.sh /home/steam/start_server.sh
COPY --chown=steam:steam scripts/healthcheck.sh /home/steam/healthcheck.sh

# Make scripts executable
RUN chmod +x /home/steam/start_server.sh /home/steam/healthcheck.sh

# Define volumes for persistent data
VOLUME ["/home/steam/rust_server/server_data"]
VOLUME ["/home/steam/rust_server/oxide"]
VOLUME ["/home/steam/rust_server/carbon"]

# Add healthcheck
HEALTHCHECK --interval=5m --timeout=10s --start-period=10m --retries=3 \
    CMD ["/home/steam/healthcheck.sh"]

# Set the entrypoint
ENTRYPOINT ["/home/steam/start_server.sh"]
