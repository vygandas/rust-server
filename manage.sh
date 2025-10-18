#!/bin/bash

# Rust aux01 Server Management Script
# Usage: ./manage.sh [command]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    echo -e "${1}${2}${NC}"
}

# Function to check if .env exists
check_env() {
    if [ ! -f .env ]; then
        print_color $YELLOW "No .env file found. Creating from .env.example..."
        cp .env.example .env
        print_color $RED "IMPORTANT: Please edit .env and change the RCON password!"
        exit 1
    fi
}

# Function to display help
show_help() {
    echo "Rust aux01 Server Management Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start       - Start the server"
    echo "  stop        - Stop the server"
    echo "  restart     - Restart the server"
    echo "  update      - Force update to latest aux01 branch"
    echo "  wipe        - Full wipe (map + blueprints)"
    echo "  wipe-map    - Map wipe only (keep blueprints)"
    echo "  logs        - Follow server logs"
    echo "  status      - Check server status"
    echo "  backup      - Backup server data"
    echo "  restore     - Restore from backup"
    echo "  rcon        - Connect to RCON console"
    echo "  build       - Build Docker image"
    echo "  help        - Show this help message"
}

# Main command processing
case "$1" in
    start)
        check_env
        print_color $GREEN "Starting aux01 server..."
        docker-compose up -d
        print_color $YELLOW "Server starting. This may take 10-15 minutes for aux01."
        print_color $YELLOW "Use '$0 logs' to monitor progress."
        ;;

    stop)
        print_color $YELLOW "Stopping server..."
        docker-compose down
        print_color $GREEN "Server stopped."
        ;;

    restart)
        print_color $YELLOW "Restarting server..."
        docker-compose restart
        print_color $GREEN "Server restarted."
        ;;

    update)
        print_color $YELLOW "Updating to latest aux01 branch..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        print_color $GREEN "Update complete. Server is starting..."
        ;;

    wipe)
        print_color $RED "WARNING: This will completely wipe the server (map + blueprints)!"
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker-compose down
            rm -rf ./server_data/*
            print_color $YELLOW "Server wiped. Starting fresh..."
            docker-compose up -d
            print_color $GREEN "Server wiped and restarted."
        else
            print_color $YELLOW "Wipe cancelled."
        fi
        ;;

    wipe-map)
        print_color $YELLOW "Map wipe only (keeping blueprints)..."
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker-compose down
            # Only remove map files, keep blueprints
            find ./server_data -name "*.map" -delete
            find ./server_data -name "*.sav" -delete
            print_color $YELLOW "Map wiped. Starting server..."
            docker-compose up -d
            print_color $GREEN "Map wipe complete."
        else
            print_color $YELLOW "Wipe cancelled."
        fi
        ;;

    logs)
        print_color $BLUE "Following server logs (Ctrl+C to exit)..."
        docker-compose logs -f rust-server
        ;;

    status)
        if docker-compose ps | grep -q "Up"; then
            print_color $GREEN "Server is running."
            docker-compose ps
        else
            print_color $RED "Server is not running."
        fi
        ;;

    backup)
        timestamp=$(date +%Y%m%d_%H%M%S)
        backup_file="backup_aux01_${timestamp}.tar.gz"
        print_color $YELLOW "Creating backup: $backup_file"
        tar -czf "$backup_file" ./server_data/
        print_color $GREEN "Backup created: $backup_file"
        ;;

    restore)
        if [ -z "$2" ]; then
            print_color $RED "Please specify backup file to restore."
            echo "Usage: $0 restore <backup_file>"
            echo ""
            echo "Available backups:"
            ls -la backup_*.tar.gz 2>/dev/null || echo "No backups found."
            exit 1
        fi

        if [ ! -f "$2" ]; then
            print_color $RED "Backup file not found: $2"
            exit 1
        fi

        print_color $YELLOW "Restoring from: $2"
        read -p "This will overwrite current server data. Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker-compose down
            rm -rf ./server_data/*
            tar -xzf "$2"
            print_color $GREEN "Restore complete. Starting server..."
            docker-compose up -d
        else
            print_color $YELLOW "Restore cancelled."
        fi
        ;;

    rcon)
        print_color $BLUE "Connecting to RCON console..."
        # Get RCON password from .env
        source .env
        docker exec -it rust-server-aux01 sh -c "echo 'Connecting to RCON on localhost:28016' && nc localhost 28016"
        ;;

    build)
        check_env
        print_color $YELLOW "Building aux01 Docker image..."
        docker-compose build --no-cache
        print_color $GREEN "Build complete."
        ;;

    help|--help|-h|"")
        show_help
        ;;

    *)
        print_color $RED "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac