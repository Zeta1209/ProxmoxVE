#!/usr/bin/env bash
set -e

REPO_BASE="https://raw.githubusercontent.com/Zeta1209/ProxmoxVE/main/project-zomboid"

if [[ $EUID -ne 0 ]]; then
  echo "❌ Run as root on a Proxmox node"
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

read -rp "IP address (CIDR): " IP
read -rp "Gateway: " GW

read -rp "Unprivileged container? [Y/n]: " UNPRIV
[[ "$UNPRIV" =~ ^[Nn]$ ]] && UNPRIV=0 || UNPRIV=1

echo
echo "📦 Available storages for TEMPLATES:"
mapfile -t TMPL_STORAGES < <(pvesm status -content vztmpl | awk 'NR>1 {print $1}')

select TMPL_STORAGE in "${TMPL_STORAGES[@]}"; do
  [[ -n "$TMPL_STORAGE" ]] && break
done

echo
echo "💾 Available storages for CONTAINER rootfs:"
mapfile -t ROOT_STORAGES < <(pvesm status -content rootdir | awk 'NR>1 {print $1}')

select ROOT_STORAGE in "${ROOT_STORAGES[@]}"; do
  [[ -n "$ROOT_STORAGE" ]] && break
done

echo "📥 Checking Debian 13 template on $TMPL_STORAGE..."
pveam update

TEMPLATE=$(pveam available | awk '/debian-13/ {print $2; exit}')

if ! pveam list "$TMPL_STORAGE" | grep -q "$TEMPLATE"; then
  echo "⬇️ Downloading template to $TMPL_STORAGE..."
  pveam download "$TMPL_STORAGE" "$TEMPLATE"
else
  echo "✅ Template already exists on $TMPL_STORAGE"
fi

echo "🚀 Creating LXC on storage '$ROOT_STORAGE'..."
pct create "$CTID" "$TMPL_STORAGE:vztmpl/$TEMPLATE" \
  --hostname "$HOSTNAME" \
  --cores "$CORES" \
  --memory "$RAM" \
  --rootfs "$ROOT_STORAGE:$DISK" \
  --net0 name=eth0,bridge=vmbr0,ip="$IP",gw="$GW" \
  --unprivileged "$UNPRIV" \
  --features nesting=1 \
  --onboot 1

pct start "$CTID"

echo "📦 Installing curl inside container..."
pct exec "$CTID" -- apt-get update
pct exec "$CTID" -- apt-get install -y curl

echo "📥 Fetching install files..."
pct exec "$CTID" -- bash -c "curl -fsSL $REPO_BASE/install_pz.sh -o /root/install_pz.sh"
pct exec "$CTID" -- bash -c "mkdir -p /opt/pz-webui"
pct exec "$CTID" -- bash -c "curl -fsSL $REPO_BASE/app.py -o /opt/pz-webui/app.py"
pct exec "$CTID" -- chmod +x /root/install_pz.sh

echo "⚙️ Running installer inside container..."
pct exec "$CTID" -- bash /root/install_pz.sh

echo
echo "✅ Installation complete!"
echo "🌐 Web UI: http://${IP%/*}:9000"
echo "🔐 Login: admin / changeme"
