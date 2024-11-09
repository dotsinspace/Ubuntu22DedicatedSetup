#!/bin/bash

# Exit on any error
set -e

#
# GLOBALS
#
USER_NAME="$1"
PASSWORD="$2"
LOG_FILE="/var/log/system_update.log"


#
# LOG
# Method for helper debbuging.
log_message() {
  echo "echo $PASSWORD | sudo -S" 
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | sudo -S tee -a "$LOG_FILE"
}


#
# SYSTEM UPGRADE
# Following section upgrade the system and its pacakges.


# Style guide.
log_message "Starting system update process..."
log_message "Updating package lists..."

# Update packages.
if sudo apt-get update >> "$LOG_FILE" 2>&1; then
  # Style guide.
  log_message "Package lists updated successfully."
else
  # Style guide.
  log_message "Failed to update package lists."

  # Exit the script.
  exit 1
fi

# Style guide.
log_message "Upgrading packages..."

# Upgrade packages.
if sudo apt-get upgrade -y >> "$LOG_FILE" 2>&1; then
  # Style guide.
  log_message "Packages upgraded successfully."
else
  # Style guide.
  log_message "Failed to upgrade packages."

  # Exit the script.
  exit 1
fi

# Style guide.
log_message "Removing unused packages..."

# Remove unref deps from ubuntu.
if sudo apt-get autoremove -y >> "$LOG_FILE" 2>&1; then
  # Style guide.
  log_message "Unused packages removed successfully."
else
  # Style guide.
  log_message "Failed to remove unused packages."
fi

# Style guide.
log_message "Cleaning up package cache..."

# Auto clean packages.
if sudo apt-get autoclean -y >> "$LOG_FILE" 2>&1; then
  # Style guide.
  log_message "Package cache cleaned successfully."
else
  # Style guide.
  log_message "Failed to clean package cache."
fi

# Check if a reboot is required
# if so the reboot.
if [ -f /var/run/reboot-required ]; then
  # Style guide.
  log_message "A system reboot is required."
else
  # Style guide.
  log_message "No reboot required."

  # Reboot the system.
  reboot
fi


# Style guide.
log_message "System update process completed."


# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  log_message "This script must be run as root!"
  exit 1
fi

# Check if both username and password are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  log_message "Usage: $0 <username> <password>"
  exit 1
fi


#
# USER SETUP
# Following section contains all the setting to setup a dynamic user.

# Style guide.
log_message "Creating user '$USER_NAME'..."

# Create the user with a home directory and bash shell
useradd -m -s /bin/bash "$USER_NAME"

# Style guide.
log_message "$USER_NAME:$PASSWORD" | chpasswd
log_message "Adding '$USER_NAME' to the sudo group..."

# Add user to group.
usermod -aG sudo "$USER_NAME"

# Style guide.
log_message "Configuring passwordless sudo for '$USER_NAME'..."
log_message "$USER_NAME ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers > /dev/null
log_message "Enabling SSH access for '$USER_NAME'..."

# Modify the SSH config to allow password authentication
sed -i '/^PasswordAuthentication /c\PasswordAuthentication yes' /etc/ssh/sshd_config

# Restart the SSH service to apply changes
systemctl restart sshd

# Echo for successful setup.
log_message "User '$USER_NAME' created successfully with a password and passwordless sudo access."

