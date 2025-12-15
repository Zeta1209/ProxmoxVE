#!/usr/bin/env bash
# Proxmox LXC installer for Project Zomboid Dedicated Server
# (similar style to ProxmoxVE Community Scripts)

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run as root on the Proxmox host!"
  exit 1
fi

echo "⚙️  Starting Project Zomboid LXC creation..."

#--- Prompt for LXC configuration ---
read -rp "Enter new LXC ID (e.g. 102): " CT_ID
read -rp "Enter container Name (hostname): " CT_NAME
read -rp "CPU cores (default 2): " CORE_COUNT
CORE_COUNT=${CORE_COUNT:-2}
read -rp "RAM in MB (default 2048): " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-2048}
read -rp "Disk size in GB (default 20): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-20}
read -rp "Network bridge (default vmbr0): " BRIDGE
BRIDGE=${BRIDGE:-vmbr0}
read -rp "Static IP for container (e.g. 192.168.1.200/24): " IPV4_ADDR
read -rp "Gateway (e.g. 192.168.1.1): " IPV4_GATE
read -rp "Privileged container? (y/N): " PRIV_CHOICE
if [[ "${PRIV_CHOICE,,}" == "y" ]]; then
  UNPRIV=0
else
  UNPRIV=1
fi

# Set a default password for root (optional, here disabled)
PW_OPT=""
# e.g. to set root password: PW_OPT="-password secretpass"

#--- Create LXC container ---
echo "⬇️  Downloading Debian 13 template (if needed)..."
pveam update
TEMPLATE=$(pveam available | awk '/Debian 13/ {print $2; exit}')
pveam download local $TEMPLATE

echo "🚀 Creating container $CT_ID..."
pct create "$CT_ID" local:vztmpl/$TEMPLATE \
  -hostname "$CT_NAME" \
  -cores "$CORE_COUNT" \
  -memory "$RAM_SIZE" \
  -swap 0 \
  -net0 name=eth0,bridge="$BRIDGE",ip="$IPV4_ADDR",gw="$IPV4_GATE" \
  -rootfs local:"${DISK_SIZE}" \
  -features nesting=1 \
  -onboot 1 \
  -unprivileged "${UNPRIV}"

if [ $? -ne 0 ]; then
  echo "❌ Failed to create LXC container."
  exit 1
fi

# Start the container
echo "⚡ Starting container $CT_ID..."
pct start "$CT_ID"

#--- Inside the LXC: prepare environment ---
echo "⚙️  Configuring container (ID $CT_ID)..."

# Update and install prerequisites
pct exec "$CT_ID" -- bash -c "apt-get update && apt-get upgrade -y"
# Set locale for SteamCMD (required):contentReference[oaicite:8]{index=8}
pct exec "$CT_ID" -- locale-gen en_US.UTF-8
pct exec "$CT_ID" -- update-locale LANG=en_US.UTF-8

# Enable multiarch and install SteamCMD:contentReference[oaicite:9]{index=9}:contentReference[oaicite:10]{index=10}
pct exec "$CT_ID" -- bash -c "apt-get install -y software-properties-common"
pct exec "$CT_ID" -- bash -c "apt-add-repository multiverse && apt-add-repository non-free"
pct exec "$CT_ID" -- bash -c "dpkg --add-architecture i386 && apt-get update"
pct exec "$CT_ID" -- apt-get install -y steamcmd

# Install Java runtime (headless) and tmux
pct exec "$CT_ID" -- apt-get install -y default-jre-headless tmux ufw

# Create zomboid user and server directory
pct exec "$CT_ID" -- useradd -m -s /bin/bash pzserver
pct exec "$CT_ID" -- mkdir /opt/pzserver
pct exec "$CT_ID" -- chown pzserver:pzserver /opt/pzserver

# Prepare SteamCMD update script for Zomboid
pct exec "$CT_ID" -- bash -c "cat >/home/pzserver/update_zomboid.txt << 'EOF'
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir /opt/pzserver/
login anonymous
app_update 380870 validate
quit
EOF"
pct exec "$CT_ID" -- chown pzserver:pzserver /home/pzserver/update_zomboid.txt

# Run SteamCMD as pzserver to download/update the server:contentReference[oaicite:11]{index=11}:contentReference[oaicite:12]{index=12}
echo "⬇️  Downloading Project Zomboid server via SteamCMD..."
pct exec "$CT_ID" -- bash -c "su - pzserver -c \"steamcmd +runscript /home/pzserver/update_zomboid.txt\""

# Open required UDP ports in container firewall (UFW):contentReference[oaicite:13]{index=13}
pct exec "$CT_ID" -- bash -c "ufw allow 16261/udp"
pct exec "$CT_ID" -- bash -c "ufw allow 16262/udp"
# (Enable UFW if desired; to avoid prompt we echo 'y')
pct exec "$CT_ID" -- bash -c "echo 'y' | ufw enable"

#--- Configure auto-start with systemd ---
echo "⏱️  Setting up systemd service for Zomboid..."
pct exec "$CT_ID" -- bash -c "cat >/etc/systemd/system/zomboid.service << 'EOF'
[Unit]
Description=Project Zomboid Server
After=network.target

[Service]
Type=simple
User=pzserver
WorkingDirectory=/opt/pzserver
ExecStart=/usr/bin/tmux new-session -d -s zomboid /opt/pzserver/start-server.sh
ExecStop=/usr/bin/tmux kill-session -t zomboid

[Install]
WantedBy=multi-user.target
EOF"
pct exec "$CT_ID" -- bash -c "systemctl enable zomboid.service"

echo "✅ Installation complete!"
echo "➤ You can start the server inside the container with: pct exec $CT_ID -- systemctl start zomboid"
echo "➤ Or attach via tmux: pct exec $CT_ID -- tmux attach -t zomboid"
