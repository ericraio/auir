# Quick Mac Mini Server Setup

## One-Line Installation

To set up your Mac Mini home server, simply run this command on your local machine (not on the Mac Mini):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/mac-mini-server/main/bootstrap.sh)
```

## What This Does

The bootstrap script will:

1. ✅ Install Xcode Command Line Tools (if needed)
2. ✅ Install Homebrew (if needed)
3. ✅ Install Git (if needed)
4. ✅ Install Ansible (if needed)
5. ✅ Generate SSH key (if needed)
6. ✅ Clone the repository
7. ✅ Create inventory file
8. ✅ Test SSH connectivity
9. ✅ Install Ansible dependencies
10. ✅ Run the full setup playbook

## Prerequisites on Mac Mini

Before running the script, ensure your Mac Mini has:

1. **Remote Login enabled**:
   - Go to System Settings > General > Sharing
   - Enable "Remote Login"
   - Note the IP address shown

2. **A user account with sudo privileges**

3. **Internet connectivity**

## After Running the Script

Once complete, you'll have:

- **Monitoring**: Grafana at `http://your-mac-mini-ip:3000`
- **Metrics**: Prometheus at `http://your-mac-mini-ip:9090`
- **Container management**: Docker with pre-configured services
- **Automated backups**: Time Machine and custom scripts
- **Secure configuration**: Firewall and security policies applied

## Manual Setup Steps

If you prefer manual setup:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/mac-mini-server.git
   cd mac-mini-server
   ```

2. **Create inventory**:
   ```bash
   # Edit inventory/hosts with your Mac Mini IP
   nano inventory/hosts
   ```

3. **Run setup**:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/site.yml --ask-become-pass
   ```

## Updating the Server

To update your server configuration:

```bash
# On your control machine
bash <(curl -fsSL https://raw.githubusercontent.com/your-username/mac-mini-server/main/bootstrap.sh)
```

This will pull the latest changes and re-run the playbook.

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**:
   ```bash
   # Test connectivity
   ssh -v username@mac-mini-ip
   ```

2. **Permission Denied**:
   - Ensure your SSH key is added to Mac Mini
   - Check Remote Login is enabled
   - Verify user has sudo privileges

3. **Ansible Command Not Found**:
   - The script will install it automatically
   - If issues persist, run `brew install ansible`

### Getting Help

For issues:
1. Check the logs: `tail -f /var/log/ansible.log`
2. Run with debug: `ansible-playbook ... -vvv`
3. Open an issue on GitHub

## Security Notes

This script:
- Creates secure SSH keys
- Configures firewall rules
- Sets up fail2ban
- Implements best practices for macOS server security
