#!/bin/bash

echo "=== Suwayomi Debug Script ==="
echo ""

echo "1. Checking Java installation..."
java -version 2>&1 || echo "Java not found!"
echo ""

echo "2. Checking Suwayomi user..."
id suwayomi 2>/dev/null || echo "Suwayomi user not found!"
echo ""

echo "3. Checking Suwayomi files..."
ls -la /opt/suwayomi/ 2>/dev/null || echo "Suwayomi directory not found!"
echo ""

echo "4. Checking service file..."
cat /etc/systemd/system/suwayomi.service 2>/dev/null || echo "Service file not found!"
echo ""

echo "5. Service status..."
systemctl status suwayomi.service --no-pager 2>/dev/null || echo "Service not found!"
echo ""

echo "6. Service logs..."
journalctl -u suwayomi.service --no-pager -n 20 2>/dev/null || echo "No logs found!"
echo ""

echo "7. Port check..."
netstat -tulpn 2>/dev/null | grep 4567 || echo "Port 4567 not listening!"
echo ""

echo "8. Manual start test..."
echo "Trying to run Suwayomi manually..."
su - suwayomi -s /bin/bash -c "cd /opt/suwayomi && timeout 10s ./suwayomi-server.sh --headless" 2>&1 || echo "Manual start failed!"
echo ""

echo "9. Configuration check..."
ls -la /home/suwayomi/.local/share/Tachidesk/ 2>/dev/null || echo "Config directory not found!"
echo ""

echo "10. Auto-login check..."
cat /etc/systemd/system/container-getty@1.service.d/override.conf 2>/dev/null || echo "Auto-login not configured!"
echo ""

echo "=== Debug Complete ==="
