#!/usr/bin/env bash

# Copyright (c) 2021-2025 Zeta1209
# License: MIT
# Source: https://github.com/Suwayomi/Suwayomi-Server

# Simple version without heavy reliance on community scripts framework
set -e

echo "Starting Suwayomi Installation..."

# Update system
echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null 2>&1 || echo "Package update had some issues but continuing..."

# Install Dependencies
echo "Installing dependencies..."
apt-get install -y curl wget unzip default-jre openjdk-21-jre-headless >/dev/null 2>&1 || {
    echo "Retrying dependency installation..."
    apt-get update >/dev/null 2>&1
    apt-get install -y curl wget unzip >/dev/null 2>&1
    apt-get install -y default-jre >/dev/null 2>&1 || apt-get install -y openjdk-17-jre-headless >/dev/null 2>&1
}
echo "Dependencies installed"

# Create Suwayomi User
echo "Creating suwayomi user..."
if ! id suwayomi >/dev/null 2>&1; then
    adduser --system --group --disabled-password --home /opt/suwayomi suwayomi >/dev/null 2>&1 || {
        useradd -r -s /bin/false -d /opt/suwayomi suwayomi
        mkdir -p /opt/suwayomi
        chown suwayomi:suwayomi /opt/suwayomi
    }
fi
echo "User created"

# Install Suwayomi Server
echo "Downloading Suwayomi Server..."
SUWAYOMI_VERSION="v2.1.1867"
mkdir -p /opt/suwayomi
cd /opt/suwayomi

# Clean up any existing files
rm -f *.tar.gz

wget -q https://github.com/Suwayomi/Suwayomi-Server/releases/download/${SUWAYOMI_VERSION}/Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz || {
    echo "Download failed, retrying..."
    sleep 2
    wget https://github.com/Suwayomi/Suwayomi-Server/releases/download/${SUWAYOMI_VERSION}/Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz
}

echo "Extracting Suwayomi Server..."
tar -xzf Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz --strip-components=1
rm -f Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz
chmod +x suwayomi-server.sh
chown -R suwayomi:suwayomi /opt/suwayomi
echo "Suwayomi Server installed"

# Create Configuration Directory
echo "Creating configuration directories..."
mkdir -p /home/suwayomi/.local/share/Tachidesk
chown -R suwayomi:suwayomi /home/suwayomi/.local || true
echo "Configuration directory created"

# Create Default Directories
echo "Creating default directories..."
mkdir -p /media/manga
mkdir -p /media/downloads
chown suwayomi:suwayomi /media/manga || true
chown suwayomi:suwayomi /media/downloads || true
echo "Default directories created"

# Create Systemd Service
echo "Creating systemd service..."
cat <<EOF >/etc/systemd/system/suwayomi.service
[Unit]
Description=Suwayomi Server - Manga Reader Server
After=network.target

[Service]
Type=simple
User=suwayomi
Group=suwayomi
WorkingDirectory=/opt/suwayomi
ExecStart=/bin/bash /opt/suwayomi/suwayomi-server.sh --headless
Restart=always
RestartSec=10
Environment="JAVA_HOME=/usr/lib/jvm/default-java"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >/dev/null 2>&1 || true
systemctl enable suwayomi.service >/dev/null 2>&1 || true
echo "Service created and enabled"

# Start Suwayomi Service
echo "Starting Suwayomi service..."
systemctl start suwayomi.service || {
    echo "Service start failed, checking Java installation..."
    java -version 2>&1 || {
        echo "Java not found, installing..."
        apt-get update >/dev/null 2>&1
        apt-get install -y default-jre >/dev/null 2>&1
    }
    
    echo "Checking service status..."
    systemctl status suwayomi.service --no-pager || true
    
    echo "Checking if suwayomi user can access files..."
    su - suwayomi -s /bin/bash -c "ls -la /opt/suwayomi/" || true
    
    echo "Trying to start service again..."
    systemctl start suwayomi.service || {
        echo "Service still failing, checking logs..."
        journalctl -u suwayomi.service --no-pager -n 20 || true
        echo "Manual start attempt..."
        su - suwayomi -s /bin/bash -c "cd /opt/suwayomi && timeout 10s ./suwayomi-server.sh --headless" || true
    }
}

echo "Waiting for service to initialize..."
sleep 15

# Check if service is actually running
if systemctl is-active suwayomi.service >/dev/null 2>&1; then
    echo "Service started successfully"
else
    echo "WARNING: Service may not be running properly"
    echo "Service status:"
    systemctl status suwayomi.service --no-pager || true
    echo "Recent logs:"
    journalctl -u suwayomi.service --no-pager -n 10 || true
fi

# Configure Suwayomi
echo "Configuring Suwayomi..."
sleep 5  # Give the service more time to create config
if [[ -f /home/suwayomi/.local/share/Tachidesk/server.conf ]]; then
    sed -i 's/server.initialOpenInBrowserEnabled=true/server.initialOpenInBrowserEnabled=false/g' /home/suwayomi/.local/share/Tachidesk/server.conf
    systemctl restart suwayomi.service || true
    echo "Configuration updated"
else
    cat <<EOF >/home/suwayomi/.local/share/Tachidesk/server.conf
server.initialOpenInBrowserEnabled=false
server.port=4567
server.ip=0.0.0.0
EOF
    chown suwayomi:suwayomi /home/suwayomi/.local/share/Tachidesk/server.conf || true
    systemctl restart suwayomi.service || true
    echo "Configuration created"
fi

# Configure Console Access
echo "Configuring console access..."
# Clear the root password for automatic login
passwd -d root >/dev/null 2>&1 || true

# Set up automatic login for console
GETTY_OVERRIDE="/etc/systemd/system/container-getty@1.service.d/override.conf"
mkdir -p $(dirname $GETTY_OVERRIDE)
cat <<EOF >$GETTY_OVERRIDE
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear --keep-baud tty%I 115200,38400,9600 \$TERM
EOF
systemctl daemon-reload >/dev/null 2>&1 || true
systemctl restart $(basename $(dirname $GETTY_OVERRIDE) | sed 's/\.d//') >/dev/null 2>&1 || true
echo "Console access configured"

# Create MOTD
echo "Setting up MOTD..."
cat <<'EOF' >/etc/motd

     _____                                               _ 
    /  ___|                                             (_)
    \ `--.  _   _ __      ____ _ _   _  ___  _ __ ___  _ _ 
     `--. \| | | |\ \ /\ / / _` | | | |/ _ \| '_ ` _ \| (_)
    /\__/ /| |_| | \ V  V / (_| | |_| | (_) | | | | | | | 
    \____/  \__,_|  \_/\_/ \__,_|\__, |\___/|_| |_| |_|_|_|
                                  __/ |                   
                                 |___/                    

   Suwayomi Server - Manga Reader Server
   
   Access your manga library at: http://IP_ADDRESS:4567
   
EOF

# Clean up
echo "Cleaning up..."
apt-get -y autoremove >/dev/null 2>&1 || true
apt-get -y autoclean >/dev/null 2>&1 || true
echo "Cleanup complete"

echo ""
echo "Suwayomi installation completed successfully!"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "Access your server at: http://${IP_ADDR}:4567"
echo ""
echo "Container access: pct enter CONTAINER_ID (no password required)"
echo ""

# Final service status check
systemctl is-active suwayomi.service >/dev/null 2>&1 && echo "Suwayomi service is running" || echo "Note: Check service status with 'systemctl status suwayomi.service'"
