#!/usr/bin/env bash
set -e

### CONFIG ###
REPO_BASE="https://raw.githubusercontent.com/Zeta1209/ProxmoxVE/main/project-zomboid"

if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root on a Proxmox node"
  exit 1
fi

echo "=== Project Zomboid LXC Installer ==="

read -rp "Container ID (CTID): " CTID
read -rp "Hostname [pzserver]: " HOSTNAME
HOSTNAME=${HOSTNAME:-pzserver}

read -rp "CPU cores [2]: " CORES
CORES=${CORES:-2}

read -rp "RAM in MB [4096]: " RAM
RAM=${RAM:-4096}

read -rp "Disk size in GB [20]: " DISK
DISK=${DISK:-20}

read -rp "IP address (CIDR, ex: 192.168.1.50/24): " IP
read -rp "Gateway: " GW

read -rp "Unprivileged container? [Y/n]: " UNPRIV
[[ "$UNPRIV" =~ ^[Nn]$ ]] && UNPRIV=0 || UNPRIV=1

echo "📦 Downloading Debian 13 template..."
pveam update
TEMPLATE=$(pveam available | awk '/debian-13/ {print $2; exit}')
pveam download local "$TEMPLATE"

echo "🚀 Creating LXC..."
pct create "$CTID" local:vztmpl/"$TEMPLATE" \
  --hostname "$HOSTNAME" \
  --cores "$CORES" \
  --memory "$RAM" \
  --rootfs local:"$DISK" \
  --net0 name=eth0,bridge=vmbr0,ip="$IP",gw="$GW" \
  --unprivileged "$UNPRIV" \
  --features nesting=1 \
  --onboot 1

pct start "$CTID"

echo "📥 Downloading install files into container..."
pct exec "$CTID" -- bash -c "curl -fsSL $REPO_BASE/install_pz.sh -o /root/install_pz.sh"
pct exec "$CTID" -- bash -c "curl -fsSL $REPO_BASE/app.py -o /opt/pz-webui/app.py"

pct exec "$CTID" -- chmod +x /root/install_pz.sh

echo "⚙️ Running container installer..."
pct exec "$CTID" -- bash /root/install_pz.sh

echo "✅ Installation complete!"
echo
echo "🎮 Project Zomboid Server is installed"
echo "🌐 Web UI: http://${IP%/*}:9000"
echo "🔐 Default Web UI login: admin / changeme"
echo "⚠️  CHANGE THE PASSWORD in /etc/systemd/system/pz-webui.service"
