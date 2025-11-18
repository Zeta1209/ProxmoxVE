# NFS Server Setup on Oracle VM for Proxmox Cluster via Tailscale

This guide explains how to set up an NFS server on an Oracle VM running Ubuntu 22.04 and make it accessible to a Proxmox cluster over Tailscale.

---

## 1. Update the System and Install NFS Server

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install nfs-kernel-server -y
```

## 2. Create a Directory to Share

```bash
sudo mkdir -p /srv/nfs/proxmox
sudo chown nobody:nogroup /srv/nfs/proxmox
sudo chmod 777 /srv/nfs/proxmox
```

> **Note:** Permissions can be tightened based on your security requirements.

## 3. Configure NFS Exports

Edit the exports file:

```bash
sudo nano /etc/exports
```

Add one line per Proxmox node (replace with your nodes' Tailscale IPs):

```bash
/srv/nfs/proxmox 100.101.102.101(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/proxmox 100.101.102.102(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/proxmox 100.101.102.103(rw,sync,no_subtree_check,no_root_squash)
```

> **Note:** Use Tailscale IPs of the Proxmox nodes, not public IPs.

## 4. Apply NFS Configuration

```bash
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

Check exported shares:

```bash
sudo exportfs -v
```

## 5. Install and Configure Tailscale

Install Tailscale on the Oracle VM:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Get the VM's Tailscale IP:

```bash
tailscale ip -4
```

## 6. Allow NFS Through Firewall (Optional)

If using UFW:

```bash
sudo ufw allow from 100.101.102.0/24 to any port nfs
sudo ufw reload
```

> **Note:** Adjust the subnet to match your Tailscale network.

## 7. Add NFS Storage to Proxmox

1. In the Proxmox Web UI: **Datacenter** → **Storage** → **Add** → **NFS**
2. Fill the fields:
   - **ID:** `nfs-proxmox` (any friendly name)
   - **Server:** `<Tailscale IP of Oracle VM>`
   - **Export:** `/srv/nfs/proxmox`
   - **Content:** `Disk image` and/or `VZDump backup file`
   - **Nodes:** select all Proxmox nodes that should use this NFS
3. Click **Add** and verify the storage is mounted.

## 8. Mount NFS Manually (Optional)

To test manually on a Proxmox node:

```bash
mkdir -p /mnt/nfs/proxmox
mount -t nfs <TAILSCALE_IP_OF_VM>:/srv/nfs/proxmox /mnt/nfs/proxmox
df -h
```

For persistent mounts, add to `/etc/fstab`:

```bash
<TAILSCALE_IP_OF_VM>:/srv/nfs/proxmox /mnt/nfs/proxmox nfs defaults 0 0
```

---

✅ **Now the Oracle VM acts as an NFS server, accessible over Tailscale by your Proxmox cluster.**
