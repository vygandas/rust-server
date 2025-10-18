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
