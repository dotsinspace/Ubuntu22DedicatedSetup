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

# Update packages.
if echo "$PASSWORD" | sudo -S apt-get update -y; then
  log_message "Package lists updated successfully."
else
  log_message "Failed to update package lists."
  exit 1
fi

log_message "Upgrading packages..."

# Upgrade packages.
if echo "$PASSWORD" | sudo -S apt-get upgrade -y; then
  log_message "Packages upgraded successfully."
else
  log_message "Failed to upgrade packages."
  exit 1
fi

log_message "Removing unused packages..."

# Remove unneeded dependencies.
if echo "$PASSWORD" | sudo -S apt-get autoremove -y; then
  log_message "Unused packages removed successfully."
else
  log_message "Failed to remove unused packages."
fi

log_message "Cleaning up package cache..."

# Auto clean packages.
if echo "$PASSWORD" | sudo -S apt-get autoclean -y; then
  log_message "Package cache cleaned successfully."
else
  log_message "Failed to clean package cache."
fi

# Check if a reboot is required, and reboot if necessary
if [ -f /var/run/reboot-required ]; then
  log_message "A system reboot is required. Rebooting now..."
  reboot
else
  log_message "No reboot required."
fi

log_message "System update process completed."

#
# USER SETUP
# Following section contains all the settings to set up a dynamic user.

log_message "Creating user '$USER_NAME'..."

# Create the user with a home directory and bash shell
useradd -m -s /bin/bash "$USER_NAME"

# Set the user's password
echo "$USER_NAME:$PASSWORD" | chpasswd

log_message "Adding '$USER_NAME' to the sudo group..."

# Add user to the sudo group
usermod -aG sudo "$USER_NAME"

log_message "Configuring passwordless sudo for '$USER_NAME'..."
echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers > /dev/null

log_message "Enabling SSH access for '$USER_NAME'..."

# Modify the SSH config to allow password authentication
sed -i '/^PasswordAuthentication /c\PasswordAuthentication yes' /etc/ssh/sshd_config

# Restart the SSH service to apply changes
systemctl restart sshd

log_message "User '$USER_NAME' created successfully with a password and passwordless sudo access."

# Optional: Reset package sources if needed
# Uncomment the following line if you need to reset your APT sources list
# sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup && sudo sed -i 's/^/#/' /etc/apt/sources.list.d/*

log_message "Script execution completed."
