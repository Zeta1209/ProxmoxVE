# Suwayomi Server - Proxmox LXC Automation Script

An automated installation script for deploying Suwayomi Server (manga reader server) in Proxmox VE LXC containers. This script provides a streamlined setup process with configurable options for both beginners and advanced users.

## 🚀 Quick Start

Run this command on your Proxmox VE host:

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/Zeta1209/ProxmoxVE/main/suwayomi/suwayomi.sh)"
```
### Very quick summary
- Do install
- Add extension repo
- Add manwha in library from sources
- Download manwha and read (or just read without downloading)

## 📖 About Suwayomi Server

Suwayomi Server is a free, open-source manga reader server that's compatible with Tachiyomi extensions. It provides:

- **Web-based manga reading** - Access your library from any device
- **Extension support** - Use the same extensions as Tachiyomi
- **Library management** - Organize manga with categories and tracking
- **Automated downloads** - Schedule updates and downloads
- **Multi-platform** - Works on any device with a web browser
- **Backup & sync** - Compatible with Tachiyomi backups

## 🛠️ Installation Options

### Option 1: Quick Setup (Recommended for most users)
- Select "**Default Settings**" when prompted
- Creates a container with sensible defaults
- No configuration required - just run and go!

### Option 2: Custom Configuration  
- Select "**Advanced Settings**" for full control
- Customize CPU, RAM, storage, networking
- **Configure mount points** for shared storage
- Perfect for specific requirements

## ⚙️ Container Specifications

| Component | Default Value | Customizable |
|-----------|---------------|--------------|
| **CPU Cores** | 2 | ✅ |
| **Memory** | 2048 MB | ✅ |
| **Storage** | 8 GB | ✅ |
| **OS** | Debian 12 | ❌ |
| **Container Type** | Unprivileged | ✅ |
| **Network** | DHCP | ✅ |

## 📁 Storage Mount Points

When using **Advanced Settings**, you can configure mount points to share storage between your Proxmox host and the Suwayomi container.

### Common Use Cases:
- **Manga Storage**: Mount your NFS share for manga files
- **Downloads**: Shared download directory
- **Backups**: Automated backup storage location

### How It Works:
1. Choose "Advanced Settings" during installation
2. When prompted, select "Yes" for mount points
3. Specify your host path (e.g., `/mnt/manga-library`)
4. Choose container mount point (e.g., `/media/manga`)
5. Script handles the rest automatically!

**Example Configuration:**
```
Host Path: /mnt/nas/manga
Container Path: /media/manga
Result: Your NAS manga collection accessible in Suwayomi
```

## 🌐 Access Your Installation

After installation completes:

1. **Open your web browser**
2. **Navigate to**: `http://[container-ip]:4567`
3. **Start reading manga!**

The container IP will be displayed at the end of installation.

## 🔧 Management Commands

### Service Control
```bash
# Check status
systemctl status suwayomi.service

# Start/stop/restart
systemctl start suwayomi.service
systemctl stop suwayomi.service
systemctl restart suwayomi.service

# View logs
journalctl -u suwayomi.service -f
```

## 🔄 Updates

To update Suwayomi to the latest version:

1. **Enter your container**: `pct enter [container-id]`
2. **Run the script**: `bash suwayomi.sh`
3. **Follow the prompts** - the script will handle downloading and installing updates

## 🗂️ File Locations

| Purpose | Location | Owner |
|---------|----------|-------|
| **Application** | `/opt/suwayomi/` | suwayomi |
| **Configuration** | `/home/suwayomi/.local/share/Tachidesk/` | suwayomi |
| **Service File** | `/etc/systemd/system/suwayomi.service` | root |
| **Default Mount** | `/media/manga/` | suwayomi |
| **Downloads** | `/media/downloads/` | suwayomi |

## 🎯 First Steps After Installation

### 1. Install Extensions
- Open the web interface
- Navigate to **Settings** → **Browse**
- Install extensions repositories to have access to the sources
<img width="809" height="394" alt="image" src="https://github.com/user-attachments/assets/ac64303e-2dbc-48d9-a38b-adc007080043" />
- Naviguate to **Browse** → **Extension** and add all your favorite sources
- Then you can finally go to **Sources** still in the **Brose** section and start to add your favorite manwha's to your library


### 2. Configure Library
- Go to **Library** settings
- Set up **Categories** for organization
- Configure **Automatic Updates** if desired
- Adjust **Download Settings** as needed

### 3. Optional: Flaresolverr Integration
If you have Flaresolverr running for Cloudflare bypass:
- Go to **Settings** → **Server**
- Configure **Flaresolverr URL** (e.g., `http://your-flaresolverr:8191`)

## 🐛 Troubleshooting

### Installation Issues
- **Verify Proxmox version**: Requires PVE 7.0+ or 8.0+
- **Check resources**: Ensure sufficient CPU/RAM available
- **Network connectivity**: Container needs internet access
- **Permission errors**: Run script as root on Proxmox host

### Service Won't Start
```bash
# Check service logs
journalctl -u suwayomi.service -n 50

# Verify Java installation
java -version

# Check file permissions
ls -la /opt/suwayomi/
```

### Web Interface Inaccessible
- **Verify service is running**: `systemctl status suwayomi.service`
- **Check port availability**: `netstat -tulpn | grep 4567`
- **Firewall issues**: Ensure port 4567 is accessible
- **Container networking**: Verify DHCP assignment or static IP

### Mount Point Issues
- **Restart container**: `pct restart [container-id]`
- **Check configuration**: View `/etc/pve/lxc/[container-id].conf`
- **Verify host path exists**: Ensure source directory is accessible
- **Permission problems**: Run `pct exec [container-id] -- chown suwayomi:suwayomi /mount/path`

## 🔒 Security Notes

- Container runs as **unprivileged** by default (recommended)
- Service runs as dedicated **suwayomi** user (not root)
- Web interface has **no authentication** by default
- Consider placing behind a **reverse proxy** for external access
- Regular **updates recommended** for security patches

## 📋 System Requirements

### Proxmox Host Requirements
- Proxmox VE 7.0 or newer
- Minimum 2 CPU cores available
- At least 2 GB RAM free
- 8+ GB storage space
- Active internet connection

### Supported Configurations
- ✅ **x86_64 architecture**
- ✅ **Debian 12 LXC containers**
- ✅ **OpenJDK 21**
- ✅ **Systemd service management**

## 🤝 Contributing

Found a bug or want to improve the script?

1. **Fork this repository**
2. **Create your feature branch**
3. **Test your changes thoroughly**
4. **Submit a pull request**

## 📄 License

This project is licensed under MIT License - see the original community-scripts license for details.

## ⚠️ Disclaimer

- This script is **not officially affiliated** with Suwayomi or Proxmox
- **Test in a non-production environment** before deploying
- **Use at your own risk** - always backup important data
- The script is provided **as-is** without warranty

## 🔗 Related Projects

- **[Suwayomi Server](https://github.com/Suwayomi/Suwayomi-Server)** - The main project
- **[Proxmox VE](https://www.proxmox.com/en/proxmox-ve)** - Virtualization platform
- **[Community Scripts](https://github.com/community-scripts/ProxmoxVE)** - Inspiration for this project

---

**Happy manga reading! 📚✨**
