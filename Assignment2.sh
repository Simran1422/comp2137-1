#!/bin/bash
set -euo pipefail

# Log message func
log() {
    echo "[STATUS REPORT] $1"
}

# Function to check if a package is installed
package_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to add SSH keys for a user
add_ssh_keys() {
    username="$1"
    ssh_dir="/home/$username/.ssh"
    mkdir -p "$ssh_dir"
    cat <<EOF >> "$ssh_dir/authorized_keys"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
EOF
    echo "Added SSH keys for user: $username"
}

# Function to create user accounts with SSH keys
create_user_accounts() {
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        if ! id "$user" &>/dev/null; then
            useradd -m -s /bin/bash "$user"
            echo "User '$user' created."
            add_ssh_keys "$user"
        else
            echo "User '$user' already exists."
        fi
    done
}

# Function to update network configuration
update_network_config() {
    echo "Updating network configuration..."
    # Check if configuration already exists
    if ! grep -q "192.168.16.21" /etc/netplan/*.yaml; then
        cat <<EOF >> /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.2
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
        netplan apply
        log "Network configuration updated."
    else
        log "Network configuration already up to date."
    fi
}

# Function to update /etc/hosts file
update_hosts_file() {
    echo "Updating /etc/hosts file..."
    if grep -q "192.168.16.21 server1" /etc/hosts; then
        log "/etc/hosts already updated."
    else
        sed -i '/192.168.16.21/d' /etc/hosts
        echo "192.168.16.21 server1" >> /etc/hosts
        log "/etc/hosts updated."
    fi
}

# Function to install and configure required software
install_configure_software() {
    echo "Installing and configuring required software..."
    # Install Apache if not installed
    if ! package_installed apache2; then
        apt update
        apt install -y apache2
    fi

    # Install Squid if not installed
    if ! package_installed squid; then
        apt update
        apt install -y squid
    fi

    # Configure firewall rules
    ufw allow OpenSSH
    ufw allow 'Apache Full'
    ufw allow 3128/tcp
    ufw --force enable
    log "Firewall configured."
}

# Main script
log "Starting system modification..."

update_network_config
update_hosts_file
install_configure_software
create_user_accounts

log "System modification completed."

