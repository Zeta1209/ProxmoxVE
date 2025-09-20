#!/usr/bin/env bash

# Copyright (c) 2021-2025 Zeta1209
# License: MIT
# Source: https://github.com/Suwayomi/Suwayomi-Server

# Simple version without heavy reliance on community scripts framework
set -e

echo "🔄 Starting Suwayomi Installation..."

# Update system
echo "📦 Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null 2>&1

# Install Dependencies
echo "⬇️ Installing dependencies..."
apt-get install -y curl wget unzip default-jre openjdk-21-jre-headless >/dev/null 2>&1
echo "✅ Dependencies installed"

# Create Suwayomi User
echo "👤 Creating suwayomi user..."
adduser --system --group --disabled-password --home /opt/suwayomi suwayomi
echo "✅ User created"

# Install Suwayomi Server
echo "📥 Downloading Suwayomi Server..."
SUWAYOMI_VERSION="v2.1.1867"
mkdir -p /opt/suwayomi
cd /opt/suwayomi
wget -q https://github.com/Suwayomi/Suwayomi-Server/releases/download/${SUWAYOMI_VERSION}/Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz
echo "📦 Extracting Suwayomi Server..."
tar -xzf Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz --strip-components=1
rm -f Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz
chmod +x suwayomi-server.sh
chown -R suwayomi:suwayomi /opt/suwayomi
echo "✅ Suwayomi Server installed"

# Create Configuration Directory
echo "📁 Creating configuration directories..."
mkdir -p /home/suwayomi/.local/share/Tachidesk
chown -R suwayomi:suwayomi /home/suwayomi/.local
echo "✅ Configuration directory created"

# Create Default Directories
echo "📁 Creating default directories..."
mkdir -p /media/manga
mkdir -p /media/downloads
chown suwayomi:suwayomi /media/manga
chown suwayomi:suwayomi /media/downloads
echo "✅ Default directories created"

# Create Systemd Service
echo "🔧 Creating systemd service..."
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
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable suwayomi.service >/dev/null 2>&1
echo "✅ Service created and enabled"

# Start Suwayomi Service
echo "🚀 Starting Suwayomi service..."
systemctl start suwayomi.service
echo "⏳ Waiting for service to initialize..."
sleep 15
echo "✅ Service started"

# Configure Suwayomi
echo "⚙️ Configuring Suwayomi..."
if [[ -f /home/suwayomi/.local/share/Tachidesk/server.conf ]]; then
    sed -i 's/server.initialOpenInBrowserEnabled=true/server.initialOpenInBrowserEnabled=false/g' /home/suwayomi/.local/share/Tachidesk/server.conf
    systemctl restart suwayomi.service
    echo "✅ Configuration updated"
else
    cat <<EOF >/home/suwayomi/.local/share/Tachidesk/server.conf
server.initialOpenInBrowserEnabled=false
server.port=4567
server.ip=0.0.0.0
EOF
    chown suwayomi:suwayomi /home/suwayomi/.local/share/Tachidesk/server.conf
    systemctl restart suwayomi.service
    echo "✅ Configuration created"
fi

# Configure Console Access
echo "🔑 Configuring console access..."
passwd -d root >/dev/null 2>&1 || true  # Don't fail if this doesn't work
echo "✅ Console access configured"

# Create MOTD
echo "📄 Setting up MOTD..."
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
echo "🧹 Cleaning up..."
apt-get -y autoremove >/dev/null 2>&1
apt-get -y autoclean >/dev/null 2>&1
echo "✅ Cleanup complete"

echo ""
echo "🎉 Suwayomi installation completed successfully!"
echo "🌐 Access your server at: http://$(hostname -I | awk '{print $1}'):4567"
echo ""
