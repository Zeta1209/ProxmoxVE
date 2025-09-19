#!/usr/bin/env bash

# Copyright (c) 2025 zeta
# Author: zeta (credit to tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Suwayomi/Suwayomi-Server

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl wget unzip default-jre openjdk-21-jre-headless
msg_ok "Installed Dependencies"

msg_info "Creating Suwayomi User"
adduser --system --group --disabled-password --home /opt/suwayomi suwayomi
msg_ok "Created Suwayomi User"

msg_info "Installing Suwayomi Server"
SUWAYOMI_VERSION="v2.1.1867"
mkdir -p /opt/suwayomi
cd /opt/suwayomi
wget https://github.com/Suwayomi/Suwayomi-Server/releases/download/${SUWAYOMI_VERSION}/Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz
tar -xzf Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz --strip-components=1
rm -f Suwayomi-Server-${SUWAYOMI_VERSION}-linux-x64.tar.gz
chmod +x suwayomi-server.sh
chown -R suwayomi:suwayomi /opt/suwayomi
msg_ok "Installed Suwayomi Server"

msg_info "Creating Configuration Directory"
mkdir -p /home/suwayomi/.local/share/Tachidesk
chown -R suwayomi:suwayomi /home/suwayomi/.local
msg_ok "Created Configuration Directory"

msg_info "Creating Systemd Service"
cat <<EOF >/etc/systemd/system/suwayomi.service
[Unit]
Description=Suwayomi Server - Manga Reader Server
After=network.target

[Service]
Type=forking
User=suwayomi
Group=suwayomi
WorkingDirectory=/opt/suwayomi
ExecStart=/opt/suwayomi/suwayomi-server.sh --headless
Restart=always
RestartSec=10
Environment="JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64"

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable suwayomi.service
msg_ok "Created Systemd Service"

msg_info "Starting Suwayomi Service"
systemctl start suwayomi.service
sleep 10
msg_ok "Started Suwayomi Service"

msg_info "Configuring Suwayomi"
# Wait for the service to create the config file
sleep 15
if [[ -f /home/suwayomi/.local/share/Tachidesk/server.conf ]]; then
    sed -i 's/server.initialOpenInBrowserEnabled=true/server.initialOpenInBrowserEnabled=false/g' /home/suwayomi/.local/share/Tachidesk/server.conf
    systemctl restart suwayomi.service
    msg_ok "Configured Suwayomi"
else
    # Create the config file if it doesn't exist
    cat <<EOF >/home/suwayomi/.local/share/Tachidesk/server.conf
server.initialOpenInBrowserEnabled=false
server.port=4567
server.ip=0.0.0.0
EOF
    chown suwayomi:suwayomi /home/suwayomi/.local/share/Tachidesk/server.conf
    systemctl restart suwayomi.service
    msg_ok "Created and Configured Suwayomi"
fi

msg_info "Creating Default Directories"
# Create default directories for potential use
mkdir -p /media/manga
mkdir -p /media/downloads
chown suwayomi:suwayomi /media/manga
chown suwayomi:suwayomi /media/downloads
msg_ok "Created Default Directories"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
