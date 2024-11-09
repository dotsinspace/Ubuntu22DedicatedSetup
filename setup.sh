#!/bin/bash

# Exit on any error
set -e

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

#
# SYSTEM UPGRADE
# Following section upgrades the system and its packages.

log_message "Starting system update process..."
log_message "Updating package lists..."

# Update & Upgrade system.
apt-get update -y && apt-get upgrade

#
# PROMETHEUS
# Node expoter for exposing system information over end point.

# Variables
VERSION="1.6.1"  # Change this to the latest version if needed
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Style guide.
log_message "Downloading Prometheus Node Exporter..."

# Download Node Exporter
wget -q $DOWNLOAD_URL -O /tmp/node_exporter.tar.gz

# Style guide.
log_message "Extracting files..."

# Extract the binary
tar -xzf /tmp/node_exporter.tar.gz -C /tmp

# Style guide.
log_message "Installing Node Exporter..."

# Move the binary to /usr/local/bin
sudo mv /tmp/node_exporter-$VERSION.linux-amd64/node_exporter $INSTALL_DIR

# Style guide.
log_message "Setting up systemd service..."

# Create a systemd service file
sudo tee $SERVICE_FILE > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
ExecStart=$INSTALL_DIR/node_exporter
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Style guide.
log_message "Starting Node Exporter service..."

# Call systemctl.
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Cleanup
rm -rf /tmp/node_exporter.tar.gz /tmp/node_exporter-$VERSION.linux-amd64

# Verify the service status
sudo systemctl status node_exporter --no-pager

# Style guide.
log_message "Node Exporter installation complete!"
