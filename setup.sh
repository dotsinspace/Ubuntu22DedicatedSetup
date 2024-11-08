#!/bin/bash

# Set up log file
LOG_FILE="/var/log/system_update.log"

# Function to log messages
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

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
