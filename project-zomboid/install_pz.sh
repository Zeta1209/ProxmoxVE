#!/usr/bin/env bash
set -e

echo "=== Installing Project Zomboid Server ==="

### -------------------------------------------------
### Debian 13: enable contrib / non-free repos (MANDATORY)
### -------------------------------------------------
echo "📦 Enabling contrib and non-free repositories (Debian 13)..."

awk '
/^Components:/ {
  print "Components: main contrib non-free non-free-firmware"
  next
}
{ print }
' /etc/apt/sources.list.d/debian.sources > /tmp/debian.sources

mv /tmp/debian.sources /etc/apt/sources.list.d/debian.sources

### -------------------------------------------------
### SteamCMD prerequisites (MANDATORY)
### -------------------------------------------------
dpkg --add-architecture i386
apt-get update -y

echo steamcmd steam/license note '' | debconf-set-selections
echo steamcmd steam/question select "I AGREE" | debconf-set-selections

### -------------------------------------------------
### Install packages
### -------------------------------------------------
apt-get install -y \
  steamcmd \
  lib32gcc-s1 \
  default-jre-headless \
  python3 python3-pip \
  tmux ufw locales

### -------------------------------------------------
### Locale
### -------------------------------------------------
echo "🌐 Setting locale..."
echo "LANG=C.UTF-8" > /etc/default/locale
export LANG=C.UTF-8

### -------------------------------------------------
### Create non-root user (MANDATORY)
### -------------------------------------------------
echo "👤 Creating pzuser..."
useradd -m -s /bin/bash pzuser || true

### -------------------------------------------------
### Prepare install directory
### -------------------------------------------------
mkdir -p /opt/pzserver
chown -R pzuser:pzuser /opt/pzserver

### -------------------------------------------------
### Install Project Zomboid (as pzuser)
### -------------------------------------------------
echo "⬇️ Installing Project Zomboid via SteamCMD..."

cat >/home/pzuser/update_zomboid.txt <<EOF
force_install_dir /opt/pzserver
login anonymous
app_update 380870 validate
quit
EOF

chown pzuser:pzuser /home/pzuser/update_zomboid.txt

su - pzuser -c "/usr/games/steamcmd +runscript /home/pzuser/update_zomboid.txt"

### -------------------------------------------------
### Web UI (Flask)
### -------------------------------------------------
echo "🧩 Installing Web UI dependencies..."
pip3 install --no-cache-dir flask

mkdir -p /opt/pz-webui

### Web UI credentials (NOT hardcoded in service)
cat >/opt/pz-webui/.env <<EOF
PZWEB_USER=admin
PZWEB_PASS=changeme
EOF

chmod 600 /opt/pz-webui/.env

### -------------------------------------------------
### systemd services
### -------------------------------------------------
echo "🛠 Creating systemd services..."

cat >/etc/systemd/system/zomboid.service <<EOF
[Unit]
Description=Project Zomboid Server
After=network.target

[Service]
Type=forking
User=pzuser
WorkingDirectory=/opt/pzserver
ExecStart=/usr/bin/tmux new-session -d -s zomboid /opt/pzserver/start-server.sh
ExecStop=/usr/bin/tmux kill-session -t zomboid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/pz-webui.service <<EOF
[Unit]
Description=Project Zomboid Web UI
After=network.target

[Service]
EnvironmentFile=/opt/pz-webui/.env
WorkingDirectory=/opt/pz-webui
ExecStart=/usr/bin/python3 /opt/pz-webui/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

### -------------------------------------------------
### Firewall
### -------------------------------------------------
echo "🔥 Configuring firewall..."
ufw allow 16261/udp
ufw allow 16262/udp
ufw allow 9000/tcp
ufw --force enable

### -------------------------------------------------
### Enable services
### -------------------------------------------------
systemctl daemon-reload
systemctl enable --now zomboid
systemctl enable --now pz-webui

echo "✅ Container setup finished"
