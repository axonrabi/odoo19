#!/bin/bash

# Script to manage local Odoo PostgreSQL backups using Docker

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 [backup|restore] [filename]"
    exit 1
fi

COMMAND=$1
FILENAME=$2
# Finding the DB container name using docker compose ps
DB_CONTAINER=$(docker compose ps -q db 2>/dev/null || echo "app-db-1")

if [ -z "$DB_CONTAINER" ]; then
    echo "Error: Could not find the database container. Make sure the docker compose environment is running."
    exit 1
fi

case "$COMMAND" in
    backup)
        echo "Taking backup of the database to $FILENAME..."
        docker exec $DB_CONTAINER pg_dump -U odoo -d postgres -F c > "$FILENAME"
        echo "Backup completed successfully."
        ;;
    restore)
        echo "Restoring database from $FILENAME..."
        if [ ! -f "$FILENAME" ]; then
            echo "Error: File $FILENAME not found."
            exit 1
        fi

        # Need to drop and recreate for clean restore, or just pg_restore.
        # Using pg_restore for custom format (-F c).
        docker exec -i $DB_CONTAINER pg_restore -U odoo -d postgres -c < "$FILENAME"
        echo "Restore completed successfully."
        ;;
    *)
        echo "Invalid command: $COMMAND. Use 'backup' or 'restore'."
        exit 1
        ;;
esac
