#!/bin/bash

# Function to log messages if verbose mode is enabled
log_message() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    fi
}

# Default values
VERBOSE=false
NAME=""
IP=""
HOSTENTRY=""

# Function to update hostname
update_hostname() {
    current_hostname=$(hostname)
    if [ "$current_hostname" != "$NAME" ]; then
        sudo hostnamectl set-hostname "$NAME"
        log_message "Changed hostname to $NAME"
    fi
}

# Function to update IP address
update_ip() {
    current_ip=$(hostname -I | awk '{print $1}')
    if [ "$current_ip" != "$IP" ]; then
        sudo sed -i "s/$current_ip/$IP/g" /etc/netplan/*.yaml
        sudo netplan apply
        log_message "Changed IP address to $IP"
    fi
}

# Function to update /etc/hosts file
update_hosts_file() {
    if ! grep -q "$NAME" /etc/hosts; then
        echo "$IP $NAME" | sudo tee -a /etc/hosts > /dev/null
        log_message "Added $NAME to /etc/hosts"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -verbose)
            VERBOSE=true
            shift
            ;;
        -name)
            NAME="$2"
            shift
            shift
            ;;
        -ip)
            IP="$2"
            shift
            shift
            ;;
        -hostentry)
            HOSTENTRY="$2 $3"
            shift
            shift
            shift
            ;;
        *)
            echo "Invalid argument: $1"
            exit 1
            ;;
    esac
done

# Ignore TERM, HUP, and INT signals
trap '' TERM HUP INT

# Update hostname, IP, and /etc/hosts
if [ -n "$NAME" ]; then
    update_hostname
fi

if [ -n "$IP" ]; then
    update_ip
fi

if [ -n "$HOSTENTRY" ]; then
    update_hosts_file
fi

exit 0
