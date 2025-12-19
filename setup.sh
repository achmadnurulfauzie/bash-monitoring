#!/bin/bash

# Setup script for system monitoring installation

set -euo pipefail

INSTALL_DIR="/opt/monitoring"
SYSTEMD_DIR="/etc/systemd/system"

echo "🚀 System Monitoring Setup"
echo "================================"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root (use sudo)"
    exit 1
fi

# 1. Create installation directory
echo "📁 Creating installation directory..."
mkdir -p "$INSTALL_DIR"/{config,logs,systemd}

# 2. Copy files
echo "📋 Copying files..."
cp monitoring.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/monitoring.sh"

cp config/.env "$INSTALL_DIR/config/"
chmod 600 "$INSTALL_DIR/config/.env"

cp systemd/system-monitor.{service,timer} "$INSTALL_DIR/systemd/"

# 3. Symlink to systemd
echo "🔗 Setting up systemd service..."
ln -sf "$INSTALL_DIR/systemd/system-monitor.service" "$SYSTEMD_DIR/"
ln -sf "$INSTALL_DIR/systemd/system-monitor.timer" "$SYSTEMD_DIR/"

# 4. Reload systemd daemon
echo "🔄 Reloading systemd daemon..."
systemctl daemon-reload

# 5. Enable timer
echo "⚙️  Enabling system-monitor.timer..."
systemctl enable system-monitor.timer

echo ""
echo "================================"
echo "✅ Setup completed successfully!"
echo ""
echo "📝 NEXT STEPS:"
echo "1. Edit configuration file:"
echo "   nano $INSTALL_DIR/config/.env"
echo ""
echo "2. Enter Telegram Bot Token and Chat ID (or Google Chat Webhook)"
echo ""
echo "3. Start the timer:"
echo "   sudo systemctl start system-monitor.timer"
echo ""
echo "4. Check status:"
echo "   sudo systemctl status system-monitor.timer"
echo "   sudo journalctl -u system-monitor.timer -f"
echo ""
echo "5. Run manual test:"
echo "   sudo $INSTALL_DIR/monitoring.sh"
echo ""
