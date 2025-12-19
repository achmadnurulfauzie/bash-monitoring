#!/bin/bash

# Setup script untuk system monitoring

set -euo pipefail

INSTALL_DIR="/opt/monitoring"
SYSTEMD_DIR="/etc/systemd/system"

echo "🚀 System Monitoring Setup"
echo "================================"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Script harus dijalankan sebagai root (gunakan sudo)"
    exit 1
fi

# 1. Buat direktori installation
echo "📁 Membuat direktori instalasi..."
mkdir -p "$INSTALL_DIR"/{config,logs,systemd}

# 2. Copy files
echo "📋 Copy files..."
cp monitoring.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/monitoring.sh"

cp config/.env "$INSTALL_DIR/config/"
chmod 600 "$INSTALL_DIR/config/.env"

cp systemd/system-monitor.{service,timer} "$INSTALL_DIR/systemd/"

# 3. Symlink ke systemd
echo "🔗 Setup systemd service..."
ln -sf "$INSTALL_DIR/systemd/system-monitor.service" "$SYSTEMD_DIR/"
ln -sf "$INSTALL_DIR/systemd/system-monitor.timer" "$SYSTEMD_DIR/"

# 4. Reload systemd daemon
echo "🔄 Reload systemd daemon..."
systemctl daemon-reload

# 5. Enable timer
echo "⚙️  Enable system-monitor.timer..."
systemctl enable system-monitor.timer

echo ""
echo "================================"
echo "✅ Setup selesai!"
echo ""
echo "📝 LANGKAH SELANJUTNYA:"
echo "1. Edit konfigurasi:"
echo "   nano $INSTALL_DIR/config/.env"
echo ""
echo "2. Masukkan Telegram Bot Token dan Chat ID (atau Google Chat Webhook)"
echo ""
echo "3. Mulai timer:"
echo "   sudo systemctl start system-monitor.timer"
echo ""
echo "4. Cek status:"
echo "   sudo systemctl status system-monitor.timer"
echo "   sudo journalctl -u system-monitor.timer -f"
echo ""
echo "5. Jalankan test manual:"
echo "   sudo $INSTALL_DIR/monitoring.sh"
echo ""
