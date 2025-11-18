# ProxmoxVE Repository

<div align="center">

![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

**A comprehensive collection of automation scripts, tools, and configurations for Proxmox Virtual Environment**

[Installation Scripts](#-installation-scripts) • [Tools & Utilities](#-tools--utilities) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 📖 About This Repository

Welcome to my Proxmox VE repository! This is a centralized collection of all my Proxmox-related work, including automated installation scripts, container configurations, helper tools, and documentation. Whether you're setting up a home lab or managing a production environment, you'll find useful resources here to streamline your Proxmox experience.

### 🎯 Repository Goals
- **Automate** complex Proxmox tasks and container deployments
- **Simplify** the setup process for popular applications
- **Document** best practices and configurations
- **Share** knowledge with the Proxmox community

## 🚀 Quick Start

Most scripts in this repository can be executed directly from your Proxmox host using:

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/Zeta1209/ProxmoxVE/main/[path-to-script])"
```

> **Note:** Always review scripts before executing them on your system. Run in a test environment first!

## 📁 Repository Structure

```
ProxmoxVE/
├── Suwayomi/           # Manga reader server automation
├── Scripts/            # Utility scripts and helpers
├── Configs/            # Configuration templates
├── Docs/               # Additional documentation
└── README.md           # You are here!
```

## 🔧 Installation Scripts

### Media & Entertainment

#### 📚 [Suwayomi Server](./Suwayomi)
Automated deployment of Suwayomi manga reader server in LXC containers.
- **Features:** Web-based manga reading, Tachiyomi extension support, library management
- **Quick Install:** 
  ```bash
  bash -c "$(wget -qLO - https://raw.githubusercontent.com/Zeta1209/ProxmoxVE/main/Suwayomi/suwayomi.sh)"
  ```
- **[Full Documentation](./Suwayomi/README.md)**

### System Utilities
*Coming soon - Additional automation scripts for various services*

## 🛠 Tools & Utilities

### Debug Scripts
- **[Suwayomi Debug](./Suwayomi/debug-suwayomi.sh)** - Troubleshooting tool for Suwayomi installations

### Helper Functions
*Documentation for utility functions and helpers coming soon*

## 📋 Prerequisites

Before using these scripts, ensure your Proxmox environment meets these requirements:

### System Requirements
- **Proxmox VE:** Version 7.0 or newer (8.0+ recommended)
- **Architecture:** x86_64/amd64
- **Network:** Active internet connection for package downloads
- **Storage:** Sufficient space for containers (varies by application)

### Required Knowledge
- Basic understanding of Proxmox VE and LXC containers
- Familiarity with Linux command line
- Understanding of networking concepts (IP addressing, DNS, etc.)

## ⚙️ Common Configuration Options

Most scripts support both default and advanced installation modes:

### Default Installation
- Quick setup with sensible defaults
- Minimal user interaction required
- Perfect for testing and home labs

### Advanced Installation
- Full control over container specifications
- Custom CPU, RAM, and storage allocation
- Network configuration options
- Mount point configuration for shared storage
- Privileged/unprivileged container selection

## 🔐 Security Considerations

- **Unprivileged Containers:** Most scripts default to unprivileged containers for better security
- **User Isolation:** Services run as dedicated users, not root
- **Network Security:** Consider implementing firewalls and reverse proxies for external access
- **Regular Updates:** Keep containers and applications updated for security patches

## 📚 Documentation

### Getting Started Guides
- [Proxmox VE Basics](./Docs/proxmox-basics.md) *(Coming Soon)*
- [LXC Container Management](./Docs/lxc-management.md) *(Coming Soon)*
- [Networking in Proxmox](./Docs/networking.md) *(Coming Soon)*

### Troubleshooting
- Check service logs: `journalctl -u [service-name] -f`
- Container access: `pct enter [container-id]`
- Network connectivity: Verify bridge configuration and DNS settings
- Resource allocation: Ensure sufficient CPU, RAM, and storage

## 🤝 Contributing

Contributions are welcome! If you have improvements, bug fixes, or new scripts to share:

1. **Fork** this repository
2. **Create** a feature branch (`git checkout -b feature/NewScript`)
3. **Commit** your changes (`git commit -m 'Add new automation script'`)
4. **Push** to the branch (`git push origin feature/NewScript`)
5. **Open** a Pull Request

### Contribution Guidelines
- Test scripts thoroughly in a non-production environment
- Include clear documentation and comments
- Follow existing code style and structure
- Update relevant README files

## 📄 License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

- These scripts are provided **as-is** without warranty
- Not officially affiliated with Proxmox or the applications being installed
- **Always test** in a non-production environment first
- **Backup** important data before running any scripts
- Use at your own risk

## 🙏 Acknowledgments

- [Proxmox VE Team](https://www.proxmox.com/) for the amazing virtualization platform
- [Community Scripts](https://github.com/community-scripts/ProxmoxVE) for inspiration and helper functions
- All the open-source projects automated by these scripts
- The Proxmox community for feedback and contributions

## 📮 Contact & Support

- **GitHub Issues:** [Report bugs or request features](https://github.com/Zeta1209/ProxmoxVE/issues)
- **Discussions:** [Ask questions and share ideas](https://github.com/Zeta1209/ProxmoxVE/discussions)

## 🔗 Useful Links

- [Proxmox VE Official Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox Forum](https://forum.proxmox.com/)
- [Linux Containers Documentation](https://linuxcontainers.org/lxc/)
- [Proxmox VE API](https://pve.proxmox.com/wiki/Proxmox_VE_API)

---

<div align="center">

**⭐ If you find this repository helpful, please consider giving it a star! ⭐**

Made with ❤️ by [Zeta1209](https://github.com/Zeta1209)

</div>