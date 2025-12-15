#!/usr/bin/env bash
set -e

echo "=== Installing Project Zomboid Server ==="

apt update
apt install -y \
  steamcmd \
  default-jre-headless \
  python3 python3-pip \
  tmux ufw locales

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

echo "👤 Creating pzserver user..."
useradd -m -s /bin/bash pzserver

mkdir -p /opt/pzserver
chown -R pzserver:pzserver /opt/pzserver

echo "⬇️ Installing Project Zomboid via SteamCMD..."
cat >/home/pzserver/update_zomboid.txt <<EOF
force_install_dir /opt/pzserver
login anonymous
app_update 380870 validate
quit
EOF

chown pzserver:pzserver /home/pzserver/update_zomboid.txt
su - pzserver -c "steamcmd +runscript ~/update_zomboid.txt"

echo "🧩 Installing Web UI dependencies..."
pip3 install flask

mkdir -p /opt/pz-webui
chown -R root:root /opt/pz-webui

echo "🛠 Creating systemd services..."

cat >/etc/systemd/system/zomboid.service <<EOF
[Unit]
Description=Project Zomboid Server
After=network.target

[Service]
User=pzserver
WorkingDirectory=/opt/pzserver
ExecStart=/usr/bin/tmux new-session -d -s zomboid /opt/pzserver/start-server.sh
ExecStop=/usr/bin/tmux kill-session -t zomboid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/pz-webui.service <<EOF
[Unit]
Description=Project Zomboid Web UI
After=network.target

[Service]
Environment=PZ_USER=admin
Environment=PZ_PASS=changeme
WorkingDirectory=/opt/pz-webui
ExecStart=/usr/bin/python3 /opt/pz-webui/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🔥 Configuring firewall..."
ufw allow 16261/udp
ufw allow 16262/udp
ufw allow 9000/tcp
ufw --force enable

systemctl daemon-reload
systemctl enable --now zomboid
systemctl enable --now pz-webui

echo "✅ Container setup finished"
