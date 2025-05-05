#!/bin/bash
# True one-liner Mac Mini setup - requires no user interaction
# curl -fsSL https://raw.githubusercontent.com/your-username/mac-mini-server/main/one-liner.sh | bash -s -- <MAC_MINI_IP> <USERNAME> <PASSWORD>

set -e

# Parse arguments
MAC_MINI_IP="$1"
MAC_MINI_USER="${2:-admin}"
MAC_MINI_PASS="$3"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check arguments
if [ -z "$MAC_MINI_IP" ] || [ -z "$MAC_MINI_PASS" ]; then
    echo "Usage: curl -fsSL https://... | bash -s -- <IP> <user> <password>"
    exit 1
fi

echo -e "${GREEN}Starting automated Mac Mini setup...${NC}"

# Install Homebrew
if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$([[ $(uname -m) == "arm64" ]] && echo /opt/homebrew/bin/brew || echo /usr/local/bin/brew) shellenv"
fi

# Install dependencies
brew install ansible git

# Clone repository
cd ~
git clone --depth 1 https://github.com/your-username/mac-mini-server.git || cd mac-mini-server
cd mac-mini-server

# Create inventory
cat > inventory/hosts << EOF
[mac_mini]
mac-mini-01 ansible_host=$MAC_MINI_IP ansible_user=$MAC_MINI_USER
EOF

# Install Ansible requirements
ansible-galaxy install -r requirements.yml

# Run all playbooks
ANSIBLE_BECOME_PASS="$MAC_MINI_PASS" ansible-playbook -i inventory/hosts \
    playbooks/setup-macos-defaults.yml \
    --extra-vars "confirm_defaults=yes" \
    -e "ansible_become_pass=$MAC_MINI_PASS"

ANSIBLE_BECOME_PASS="$MAC_MINI_PASS" ansible-playbook -i inventory/hosts \
    playbooks/site.yml \
    -e "ansible_become_pass=$MAC_MINI_PASS"

echo -e "${GREEN}✓ Mac Mini setup complete!${NC}"
echo "Access Grafana: http://$MAC_MINI_IP:3000"
echo "Access Prometheus: http://$MAC_MINI_IP:9090"
