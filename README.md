# Suwayomi Server Proxmox VE Helper Script

This repository contains a Proxmox VE Helper Script for automatically installing Suwayomi Server in a Debian LXC container. The script follows the same patterns and UI as the popular tteck/community-scripts helper scripts.

## What is Suwayomi Server?

Suwayomi Server is a free and open-source manga reader server that runs extensions built for Mihon (Tachiyomi). It allows you to:

- Install and execute Mihon (Tachiyomi)'s Extensions
- Search and browse installed sources  
- Maintain a library with categories
- Automated library updates and downloads
- Backup and restore support
- Track via MyAnimeList, AniList, MangaUpdates, etc.
- OPDS support

## Features

- **Interactive Installation**: Choose between default and advanced settings
- **Automated Setup**: Complete installation and configuration of Suwayomi Server
- **Service Management**: Systemd service for automatic startup and management
- **Mount Support**: Optional host-to-LXC mount point configuration
- **Headless Configuration**: Automatically configured to run without opening browser
- **Update Support**: Built-in update functionality

## Files Structure

```
├── suwayomi.sh          # Main installation script (with integrated mount point support)
├── suwayomi-install.sh  # Installation script (called by main script)
└── README.md           # This documentation
```

## Installation

### Method 1: Direct Download and Run (Recommended for Local Testing)

1. Download the script files to your Proxmox host:
   ```bash
   wget https://your-repo/suwayomi.sh
   chmod +x suwayomi.sh
   ```

2. Run the script:
   ```bash
   bash suwayomi.sh
   ```

### Method 2: Run from URL (Future - when hosted)

Once you host these scripts, users can run:
```bash
bash -c "$(wget -qLO - https://your-repo/suwayomi.sh)"
```

## Script Options

When you run the script, you'll be presented with several options:

### 1. Default Settings
- **Container Type**: Unprivileged
- **CPU Cores**: 2
- **RAM**: 2048 MB
- **Disk Size**: 8 GB
- **OS**: Debian 12
- **Network**: DHCP
- **Mount Points**: None

### 2. Default Settings (Verbose)
Same as default but with verbose output for troubleshooting.

### 3. Advanced Settings
Allows you to customize:
- Container ID
- Hostname
- CPU cores
- RAM allocation
- Disk size
- Network configuration (static IP, VLAN, etc.)
- DNS settings
- SSH access
- **Mount points** (NEW!)

### 4. Mount Points Configuration

When using **Advanced Settings**, you'll be asked if you want to add a mount point:

- **Question**: "Do you want to add a mount point from host to LXC?"
- **Host Path**: Path on your Proxmox host (e.g., `/mnt/manga`)
- **LXC Path**: Mount point inside the container (e.g., `/media/manga`)

**Features**:
- Automatically creates host directory if it doesn't exist
- Configures proper permissions inside the container
- Automatically restarts the container to apply the mount
- Sets ownership to the suwayomi user

**Note**: The mount point is configured during installation and is immediately available after setup completes.

## Default Configuration

- **Service User**: `suwayomi`
- **Installation Directory**: `/opt/suwayomi`
- **Data Directory**: `/home/suwayomi/.local/share/Tachidesk`
- **Service Name**: `suwayomi.service`
- **Web Interface**: `http://[container-ip]:4567`
- **Java Version**: OpenJDK 21

## Post-Installation

1. **Access the Web Interface**: 
   Navigate to `http://[your-container-ip]:4567` in your browser

2. **Install Extensions**:
   - Go to Extensions tab
   - Browse and install manga source extensions

3. **Configure Library**:
   - Add manga to your library
   - Set up categories
   - Configure automatic updates

4. **Optional - Flaresolverr Integration**:
   If you have a Flaresolverr server running, you can configure it in Suwayomi's settings.

5. **Mount Points** (if configured):
   - Your mount points are immediately available
   - Default locations: `/media/manga` and `/media/downloads`
   - Perfect for storing manga downloads and library data

## Service Management

The script creates a systemd service for easy management:

```bash
# Check status
systemctl status suwayomi.service

# Start/Stop/Restart
systemctl start suwayomi.service
systemctl stop suwayomi.service
systemctl restart suwayomi.service

# View logs
journalctl -u suwayomi.service -f
```

## Updating Suwayomi

The script includes an update function. To update Suwayomi to the latest version:

```bash
bash suwayomi.sh
```

Then select the update option when running inside the LXC container.

## Troubleshooting

### Container Won't Start
- Check if the container has enough resources (2 CPU cores, 2GB RAM minimum)
- Verify network connectivity
- Check Proxmox logs: `pct list` and `pct status [container-id]`

### Suwayomi Won't Start
- Check service status: `systemctl status suwayomi.service`
- View logs: `journalctl -u suwayomi.service -f`
- Verify Java installation: `java -version`
- Check permissions: `ls -la /opt/suwayomi`

### Web Interface Not Accessible
- Verify the service is running: `systemctl status suwayomi.service`
- Check if port 4567 is being used: `netstat -tulpn | grep 4567`
- Verify firewall settings on both host and container
- Check the configuration file: `/home/suwayomi/.local/share/Tachidesk/server.conf`

### Mount Points Not Working
- Mount points are configured automatically during installation
- If you need to add mount points later, you can manually edit `/etc/pve/lxc/[container-id].conf`
- Add line: `mp0: /host/path,mp=/container/path`
- Restart the container: `pct restart [container-id]`
- Set permissions: `pct exec [container-id] -- chown suwayomi:suwayomi /container/path`

## Configuration Files

### Main Configuration
- **Location**: `/home/suwayomi/.local/share/Tachidesk/server.conf`
- **Key Settings**:
  ```
  server.initialOpenInBrowserEnabled=false
  server.port=4567
  server.ip=0.0.0.0
  ```

### Service Configuration  
- **Location**: `/etc/systemd/system/suwayomi.service`
- **User**: `suwayomi`
- **Working Directory**: `/opt/suwayomi`

## Requirements

### Host Requirements
- Proxmox VE 7.0+ or 8.0+
- Available CPU cores: 2+
- Available RAM: 2GB+
- Available disk space: 8GB+
- Internet connection for downloading

### Container Requirements
- Debian 12 (automatically configured)
- OpenJDK 21 (automatically installed)
- Network connectivity

## Contributing

To modify or extend these scripts:

1. **Main Script (`suwayomi.sh`)**:
   - Modify default values in the `var_*` variables
   - Update the APP name and source URL
   - Adjust the final URL message

2. **Install Script (`suwayomi-install.sh`)**:
   - Update Suwayomi version in `SUWAYOMI_VERSION`
   - Modify installation steps as needed
   - Adjust configuration parameters

3. **Testing**:
   - Test on a clean Proxmox environment
   - Verify both default and advanced installation modes
   - Test the update functionality

## Version Information

- **Suwayomi Server Version**: v2.1.1867
- **Supported OS**: Debian 12
- **Java Version**: OpenJDK 21
- **Script Version**: 1.0

## License

This script follows the same MIT license as the community-scripts project.

## Support

For issues related to:
- **Script Installation**: Create an issue in this repository
- **Suwayomi Server**: Visit the [official Suwayomi GitHub](https://github.com/Suwayomi/Suwayomi-Server)
- **Proxmox VE**: Consult the [Proxmox documentation](https://pve.proxmox.com/pve-docs/)

## Links

- [Suwayomi Server GitHub](https://github.com/Suwayomi/Suwayomi-Server)
- [Community Scripts GitHub](https://github.com/community-scripts/ProxmoxVE)
- [Proxmox VE Helper Scripts](https://community-scripts.github.io/ProxmoxVE/)

---

**Disclaimer**: This script is not officially affiliated with Suwayomi or Proxmox. Use at your own risk and always test in a non-production environment first.
