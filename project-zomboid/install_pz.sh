#!/usr/bin/env bash
set -e

CONFIG_DIR="/opt/pzserver/config"
SERVER_NAME="servertest"
ADMIN_USER="admin"
ADMIN_PASS="changeme"

echo "=== Installing Project Zomboid Server ==="

### -------------------------------------------------
### Enable contrib / non-free (Debian 13)
### -------------------------------------------------
awk '
/^Components:/ {
  print "Components: main contrib non-free non-free-firmware"
  next
}
{ print }
' /etc/apt/sources.list.d/debian.sources > /tmp/debian.sources
mv /tmp/debian.sources /etc/apt/sources.list.d/debian.sources

dpkg --add-architecture i386
apt-get update -y

echo steamcmd steam/license note '' | debconf-set-selections
echo steamcmd steam/question select "I AGREE" | debconf-set-selections

apt-get install -y \
  steamcmd lib32gcc-s1 \
  default-jre-headless \
  python3 python3-flask \
  ufw ca-certificates locales

echo "LANG=C.UTF-8" > /etc/default/locale

### -------------------------------------------------
### User & directories
### -------------------------------------------------
useradd -m -s /bin/bash pzuser || true

mkdir -p /opt/pzserver
mkdir -p "$CONFIG_DIR"
chown -R pzuser:pzuser /opt/pzserver "$CONFIG_DIR"

### -------------------------------------------------
### SteamCMD install (scripted – REQUIRED)
### -------------------------------------------------

cat >/home/pzuser/steamcmd_pz.txt <<EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir /opt/pzserver
login anonymous
app_update 380870 validate
quit
EOF

chown pzuser:pzuser /home/pzuser/steamcmd_pz.txt

su - pzuser -c "
export HOME=/home/pzuser
mkdir -p ~/.steam ~/.local/share/Steam
/usr/games/steamcmd +@sSteamCmdForcePlatformType linux +runscript /home/pzuser/steamcmd_pz.txt
"

### -------------------------------------------------
### Centralized server config (EDIT THIS LATER)
### -------------------------------------------------
cat > "$CONFIG_DIR/server.ini" <<EOF
PublicName=My Zomboid Server
PublicDescription=Dedicated Server
MaxPlayers=16
Password=
PauseEmpty=true
Open=true

DefaultPort=16261
UDPPort=16262

AdminUsername=$ADMIN_USER
AdminPassword=$ADMIN_PASS

Mods=
WorkshopItems=
EOF

chown -R pzuser:pzuser "$CONFIG_DIR"

### -------------------------------------------------
### Seed Zomboid config (CRITICAL)
### -------------------------------------------------
su - pzuser -c "
mkdir -p ~/Zomboid/Server
cp $CONFIG_DIR/server.ini ~/Zomboid/Server/$SERVER_NAME.ini
"

### -------------------------------------------------
### systemd service (NON-INTERACTIVE SAFE)
### -------------------------------------------------
cat >/etc/systemd/system/zomboid.service <<EOF
[Unit]
Description=Project Zomboid Server
After=network.target

[Service]
User=pzuser
WorkingDirectory=/opt/pzserver
ExecStart=/opt/pzserver/start-server.sh -servername $SERVER_NAME
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF

### -------------------------------------------------
### Firewall
### -------------------------------------------------
ufw allow 16261/udp
ufw allow 16262/udp
ufw --force enable

systemctl daemon-reload
systemctl enable --now zomboid

echo "✅ Installation complete"
echo "📝 Edit config at: $CONFIG_DIR/server.ini"
echo "🔄 After edits: systemctl restart zomboid"
