# Proxmox pvestatd Service Auto-Restart Fix

This repository provides a solution for the issue where the Proxmox `pvestatd` service occasionally fails.

## Problem

The Proxmox Status Daemon (`pvestatd.service`) sometimes terminates unexpectedly with a signal error:

```
× pvestatd.service - PVE Status Daemon
     Loaded: loaded (/lib/systemd/system/pvestatd.service; enabled; preset: enabled)
     Active: failed (Result: signal) since Thu 2025-03-27 13:37:30 EDT; 23h ago
   Duration: 1w 22h 53min 3.794s
   Main PID: 930 (code=killed, signal=ABRT)
```

This failure can cause monitoring and status information to be unavailable until manually restarted.

## Solution

Configure systemd to automatically restart the service when it fails using a systemd override file.

### Installation Steps

1. Create a systemd override directory for the pvestatd service:

```bash
mkdir -p /etc/systemd/system/pvestatd.service.d/
```

2. Create an override configuration file:

```bash
cat > /etc/systemd/system/pvestatd.service.d/override.conf << 'EOF'
[Service]
Restart=always
RestartSec=5
EOF
```

3. Reload the systemd configuration:

```bash
systemctl daemon-reload
```

4. Restart the pvestatd service:

```bash
systemctl restart pvestatd
```

### Verification

To verify that the override has been applied correctly:

```bash
systemctl show pvestatd.service -p Restart
```

This should output: `Restart=always`

## Additional Considerations

- The `RestartSec=5` directive sets a 5-second delay before restart attempts
- For persistent issues, consider investigating the root cause in Proxmox logs
- Setting up monitoring for this service is recommended to track restart events

## Compatibility

Tested on:
- Proxmox VE 8.x
- Proxmox VE 7.x

## License

This project is licensed under the MIT License - see the LICENSE file for details.
