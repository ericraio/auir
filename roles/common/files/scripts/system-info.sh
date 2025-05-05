#!/bin/bash
# Display system information

echo "=== Mac Mini System Information ==="
echo
echo "Hardware:"
system_profiler SPHardwareDataType | grep -E "(Model|Processor|Memory)"
echo
echo "Network:"
networksetup -getinfo "Ethernet" | grep -E "(IP address|Subnet mask|Router)"
echo
echo "Storage:"
df -h | grep -E "(Filesystem|/System/Volumes/Data)"
echo
echo "Uptime:"
uptime
echo
echo "Docker Status:"
docker info 2>/dev/null | grep -E "(Containers|Images|Server Version)" || echo "Docker not running"
echo
echo "Services:"
launchctl list | grep -E "(nginx|docker|prometheus|grafana)"
