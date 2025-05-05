#!/bin/bash

# Mac Mini Home Server Bootstrap Script
# This script clones the repository, installs dependencies, and runs the Ansible playbook
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/your-username/mac-mini-server/main/bootstrap.sh)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/ericraio/auir.git"
ANSIBLE_VERSION=">=8.0"
PROJECT_DIR="$HOME/auir"

echo -e "${GREEN}=== Mac Mini Home Server Setup ===${NC}"
echo ""

# Check if running on macOS
if [[ $(uname) != "Darwin" ]]; then
    echo -e "${RED}Error: This script is designed for macOS only${NC}"
    exit 1
fi

# Function to install Command Line Tools if not present
install_xcode_cli_tools() {
    if ! xcode-select --print-path >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
        xcode-select --install
        echo "Please complete the Xcode Command Line Tools installation manually and re-run this script."
        exit 1
    fi
}

# Function to install Homebrew if not present
install_homebrew() {
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo -e "${GREEN}Homebrew is already installed${NC}"
    fi
}

# Function to install Ansible
install_ansible() {
    if ! command -v ansible >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Ansible...${NC}"
        brew install ansible
    else
        echo -e "${GREEN}Ansible is already installed${NC}"
    fi
}

# Function to install Git if not present
install_git() {
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing Git...${NC}"
        brew install git
    else
        echo -e "${GREEN}Git is already installed${NC}"
    fi
}

# Function to check SSH key
check_ssh_key() {
    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo -e "${YELLOW}No SSH key found. Generating new SSH key...${NC}"
        ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$HOME/.ssh/id_ed25519" -N ""
        echo ""
        echo -e "${GREEN}New SSH key generated at $HOME/.ssh/id_ed25519${NC}"
        echo ""
        echo -e "${YELLOW}Please add the following public key to the Mac Mini's authorized_keys:${NC}"
        echo ""
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
        read -p "Press Enter after adding the SSH key to the Mac Mini..."
    fi
}

# Function to clone the repository
clone_repository() {
    if [ -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}Repository directory exists. Updating...${NC}"
        cd "$PROJECT_DIR"
        git pull origin main
    else
        echo -e "${YELLOW}Cloning repository...${NC}"
        git clone "$REPO_URL" "$PROJECT_DIR"
        cd "$PROJECT_DIR"
    fi
}

# Function to setup SSH Key management
create_ssh_keys() {
  # Create SSH key management
  if [ ! -f "~/.ssh/mac-mini-keys.pub" ]; then
      echo "Generating SSH key for Mac Mini..."
      ssh-keygen -t ed25519 -f ~/.ssh/mac-mini-keys -N "" -C "mac-mini-server"
      
      echo "Add this public key to the Mac Mini:"
      cat ~/.ssh/mac-mini-keys.pub
      read -p "Press Enter when done..."
  fi

  # Copy SSH key to authorized_keys
  echo "Configuring SSH access..."
  ssh-copy-id -i ~/.ssh/mac-mini-keys.pub "$MAC_MINI_USER@$MAC_MINI_IP"
}

# Function to create inventory file if it doesn't exist
create_inventory() {
    if [ ! -f "$PROJECT_DIR/inventory/hosts" ]; then
        echo -e "${YELLOW}Creating inventory file...${NC}"
        mkdir -p "$PROJECT_DIR/inventory"
        
        echo "Enter Mac Mini server IP address: "
        read -r MAC_MINI_IP
        
        echo "Enter Mac Mini username (default: admin): "
        read -r MAC_MINI_USER
        MAC_MINI_USER=${MAC_MINI_USER:-admin}
        
        cat > "$PROJECT_DIR/inventory/hosts" << EOF
[mac_mini]
mac-mini-01 ansible_host=$MAC_MINI_IP

[mac_mini:vars]
ansible_user=$MAC_MINI_USER
ansible_become=yes
ansible_become_method=sudo
ansible_python_interpreter=/usr/bin/python3
EOF
        echo -e "${GREEN}Inventory file created${NC}"
    fi
}

# Function to verify connectivity
verify_connectivity() {
    echo -e "${YELLOW}Testing SSH connectivity to Mac Mini...${NC}"
    if ansible all -i "$PROJECT_DIR/inventory/hosts" -m ping; then
        echo -e "${GREEN}SSH connectivity successful${NC}"
    else
        echo -e "${RED}Failed to connect to Mac Mini${NC}"
        echo "Please check:"
        echo "1. SSH key is correctly added to Mac Mini"
        echo "2. Mac Mini IP address is correct"
        echo "3. Mac Mini has Remote Login enabled (System Settings > General > Sharing)"
        exit 1
    fi
}

# Function to install Ansible dependencies
install_ansible_dependencies() {
    echo -e "${YELLOW}Installing Ansible Galaxy collections...${NC}"
    ansible-galaxy install -r "$PROJECT_DIR/requirements.yml"
}

# Function to run the playbooks
run_playbooks() {
    echo -e "${YELLOW}Running Ansible playbooks...${NC}"
    cd "$PROJECT_DIR"
    
    # Store sudo password
    echo "Enter your sudo password for the Mac Mini (used for privilege escalation):"
    read -s -p "Password: " SUDO_PASS
    echo
    
    # Run macOS defaults configuration first
    echo -e "${YELLOW}Configuring macOS system defaults...${NC}"
    ANSIBLE_BECOME_PASS="$SUDO_PASS" ansible-playbook -i inventory/hosts \
        playbooks/setup-macos-defaults.yml \
        --extra-vars "confirm_defaults=yes" \
        -e "ansible_become_pass=$SUDO_PASS"
    
    echo -e "${GREEN}✓ macOS system defaults configured${NC}"
    echo ""
    
    # Run main site playbook
    echo -e "${YELLOW}Running main configuration playbook...${NC}"
    ANSIBLE_BECOME_PASS="$SUDO_PASS" ansible-playbook -i inventory/hosts \
        playbooks/site.yml \
        -e "ansible_become_pass=$SUDO_PASS"
    
    # Run optional playbooks
    echo -e "${YELLOW}Would you like to run additional playbooks? (y/n)${NC}"
    read -p ": " RUN_ADDITIONAL
    
    if [[ "$RUN_ADDITIONAL" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Running networking playbook...${NC}"
        ANSIBLE_BECOME_PASS="$SUDO_PASS" ansible-playbook -i inventory/hosts \
            playbooks/setup-networking.yml \
            -e "ansible_become_pass=$SUDO_PASS"
        
        echo -e "${YELLOW}Running services playbook...${NC}"
        ANSIBLE_BECOME_PASS="$SUDO_PASS" ansible-playbook -i inventory/hosts \
            playbooks/setup-services.yml \
            -e "ansible_become_pass=$SUDO_PASS"
        
        echo -e "${YELLOW}Running security playbook...${NC}"
        ANSIBLE_BECOME_PASS="$SUDO_PASS" ansible-playbook -i inventory/hosts \
            playbooks/setup-security.yml \
            -e "ansible_become_pass=$SUDO_PASS"
    fi
}

# Main execution
main() {
    echo -e "${GREEN}Starting Mac Mini Home Server setup...${NC}"
    echo ""
    
    # Install prerequisites
    install_xcode_cli_tools
    install_homebrew
    install_git
    install_ansible
    
    # Setup SSH
    #check_ssh_key
    
    # Clone repository
    #clone_repository

    # Create SSH Keys
    #create_ssh_keys
 
    # Create inventory if needed
    create_inventory
    
    # Verify connectivity
    verify_connectivity
    
    # Install dependencies
    install_ansible_dependencies
    
    # Run playbook
    run_playbook
    
    echo ""
    echo -e "${GREEN}=== Setup Complete! ===${NC}"
    echo ""
    echo "Your Mac Mini home server is now configured!"
    echo ""
    echo "Next steps:"
    echo "1. Access Grafana at http://$MAC_MINI_IP:3000 (default: admin/admin)"
    echo "2. Access Prometheus at http://$MAC_MINI_IP:9090"
    echo "3. Check Docker containers: docker ps"
    echo "4. View logs: cd $PROJECT_DIR && git pull"
    echo ""
    echo "For updates, simply run this command again:"
    echo "bash <(curl -fsSL https://raw.githubusercontent.com/ericraio/auir/main/bootstrap.sh)"
}

# Execute main function
main
