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

# Style guide.
log_message "Starting system update process..."
log_message "Updating package lists..."

# Update & Upgrade system.
apt-get update -y && apt-get upgrade -y


#
# PROMETHEUS
# System monitoring tool.

# Variables
VERSION="1.6.1"  # Change this to the latest version if needed
DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"

# Style guide.
log_message "Checking if Node Exporter is already installed..."

# Check if Node Exporter is already installed
if command -v node_exporter &> /dev/null; then
  # Style guide.
  log_message "Node Exporter is already installed. Checking version..."

  # Get installed version.
  INSTALLED_VERSION=$(node_exporter --version 2>&1 | grep -oP 'version [0-9]+\.[0-9]+\.[0-9]+')
  
  if [ "$INSTALLED_VERSION" = "version $VERSION" ]; then
    # Style guide.
    log_message "Node Exporter version $INSTALLED_VERSION is already installed. Skipping installation."
  else
    # Style guide.
    log_message "Different version detected. Upgrading to version $VERSION..."

    # Stop node expoter.
    sudo systemctl stop node_exporter

    # Proceed to upgrade
    INSTALL_NODE_EXPORTER=true
  fi
else
  # Style guide.
  log_message "Node Exporter is not installed. Proceeding with installation..."

  # Update flag.
  INSTALL_NODE_EXPORTER=true
fi

# Download and install Node Exporter if needed
if [ "$INSTALL_NODE_EXPORTER" = true ]; then
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

  # Reload systemd and restart the service
  sudo systemctl daemon-reload
  sudo systemctl enable node_exporter
  sudo systemctl restart node_exporter

  # Cleanup download
  rm -rf /tmp/node_exporter.tar.gz /tmp/node_exporter-$VERSION.linux-amd64
fi

# Style guide.
log_message "Node Exporter setup completed!"

# Verify the service status
sudo systemctl status node_exporter --no-pager


#
# DOCKER INSTALLATION
#

# Style guide.
log_message "Checking if Docker is already installed..."

if command -v docker &> /dev/null; then
  # Style guide.
  log_message "Docker is already installed. Skipping installation."
else
  # Style guide.
  log_message "Docker is not installed. Proceeding with installation..."

  # Install prerequisites
  apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release

  # Add Docker's official GPG key
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

  # Set up the Docker repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Install Docker Engine
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Style guide.
  log_message "Docker installation completed!"
fi

# Style guide.
log_message "Starting Docker service..."

# Start and enable Docker service
sudo systemctl enable docker
sudo systemctl restart docker
sudo systemctl status docker --no-pager

# Style guide.
log_message "Docker setup completed!"
