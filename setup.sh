#!/bin/bash

# Exit on any error
set -e

#
# GLOBALS
#
USER_NAME="$1"
PASSWORD="$2"

#
# LOG
# Method for helper debugging.
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  log_message "This script must be run as root!"
  exit 1
fi

# Check if both username and password are provided as arguments
if [ -z "$USER_NAME" ] || [ -z "$PASSWORD" ]; then
  log_message "Usage: $0 <username> <password>"
  exit 1
fi

#
# SYSTEM UPGRADE
# Following section upgrades the system and its packages.

log_message "Starting system update process..."
log_message "Updating package lists..."

# Update & Upgrade system.
apt-get update -y && apt-get upgrade


#
# USER CREATION
# This section creates the new user, sets password, and adds the user to the sudo group.

# Style guide.
log_message "Creating user '$USER_NAME' with home directory..."

# Create user with home directory
useradd -m -s /bin/bash "$USER_NAME"

# Set the user's password
echo "$USER_NAME:$PASSWORD" | chpasswd

# Add the user to the sudo group
usermod -aG sudo "$USER_NAME"

# Style guide.
log_message "User '$USER_NAME' created and added to the sudo group."
log_message "User created successfully."
