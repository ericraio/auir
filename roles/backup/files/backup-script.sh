#!/bin/bash

# Mac Mini Backup Script
# This script performs incremental backups to the configured destination

BACKUP_DEST="/Volumes/Backup"
LOG_FILE="/var/log/backup.log"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

echo "[$TIMESTAMP] Starting backup..." | tee -a "$LOG_FILE"

# Check if backup destination is mounted
if [ ! -d "$BACKUP_DEST" ]; then
    echo "[$TIMESTAMP] ERROR: Backup destination not found!" | tee -a "$LOG_FILE"
    exit 1
fi

# Create backup directory structure
BACKUP_DIR="$BACKUP_DEST/mac-mini-$DATE"
mkdir -p "$BACKUP_DIR"

# Perform rsync backup
rsync -av --delete \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='.Trash' \
    --exclude='node_modules' \
    --exclude='.cache' \
    --log-file="$LOG_FILE" \
    /Users \
    /opt \
    /Applications \
    "$BACKUP_DIR/"

# Create tarball of important configs
tar -czf "$BACKUP_DIR/configs_$TIMESTAMP.tar.gz" \
    /etc \
    /opt/docker \
    /opt/prometheus \
    /opt/grafana

# Cleanup old backups (keep last 7 days)
find "$BACKUP_DEST" -name "mac-mini-*" -type d -mtime +7 -exec rm -rf {} \;

echo "[$TIMESTAMP] Backup completed successfully!" | tee -a "$LOG_FILE"
