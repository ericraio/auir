#!/bin/bash

# System cleanup script for Mac Mini

echo "Starting maintenance script..."

# Clean up old packages
brew cleanup

# Update system
softwareupdate -i -a

# Clean up Docker
docker system prune -f

# Check disk space
df -h

# Restart services if needed
launchctl list | grep -E '(nginx|docker)' | while read service; do
    echo "Restarting $service..."
    launchctl restart $service
done

echo "Maintenance complete!"
