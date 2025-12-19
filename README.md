# System Monitoring Script with Notifications

A Bash script for monitoring CPU, Memory, and Disk usage with automated notifications to Telegram or Google Chat.

## 📋 Features

✅ Monitor CPU Usage  
✅ Monitor Memory Usage  
✅ Monitor Disk Usage  
✅ Display Top 3 Processes (Memory)  
✅ Display Top 3 Processes (CPU)  
✅ Telegram Notifications  
✅ Google Chat Notifications  
✅ Configurable Thresholds  
✅ Detailed Logging  
✅ Systemd Timer Integration  

## 🔧 Prerequisites

- Ubuntu/Debian Linux
- `curl` for HTTP requests
- `top` and `ps` utilities (pre-installed on most distros)
- Internet access for notifications
- Root/sudo privileges for installation

## 📦 Installation

### 1. Clone or Download Files

```bash
git clone https://github.com/your-repo/system-monitoring.git
cd system-monitoring
```

### 2. Configure Notification Settings

Edit the configuration file with your notification credentials:

```bash
nano config/.env
```

**For Telegram:**
- `TELEGRAM_BOT_TOKEN`: Obtain from [@BotFather](https://t.me/botfather) on Telegram
- `TELEGRAM_CHAT_ID`: Get your chat ID from [@userinfobot](https://t.me/userinfobot) or forward a message to your bot

**For Google Chat:**
- `GOOGLE_CHAT_WEBHOOK_URL`: Create a webhook in your Google Chat space (Manage > Apps & integrations > Incoming webhooks)

**Configure Thresholds (percentage 0-100):**
- `CPU_THRESHOLD`: CPU usage alert threshold (default: 40%)
- `MEMORY_THRESHOLD`: Memory usage alert threshold (default: 40%)
- `DISK_THRESHOLD`: Disk usage alert threshold (default: 40%)

**Other Settings:**
- `NOTIFICATION_TYPE`: Choose `telegram`, `google_chat`, or `both`
- `ALERT_TITLE`: Server identifier for alerts (e.g., PROD-SERVER-01)
- `DEBUG`: Set to `true` for detailed debug logging

Example configuration:

```env
NOTIFICATION_TYPE=telegram
TELEGRAM_BOT_TOKEN="1234567890:ABCDefGHIJKlmnoPQRstUVwxyz"
TELEGRAM_CHAT_ID="123456789"
CPU_THRESHOLD=75
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90
ALERT_TITLE=PROD-SERVER-01
DEBUG=false
```

### 3. Run Installation Script

Execute the setup script with sudo:

```bash
sudo bash setup.sh
```

This will:
- Create installation directory at `/opt/monitoring/`
- Copy all necessary files
- Set appropriate permissions
- Create systemd service and timer files
- Reload systemd daemon
- Enable the monitoring timer

## 🚀 Usage

### Manual Execution

Run the monitoring script manually:

```bash
sudo /opt/monitoring/monitoring.sh
```

### Start the Systemd Timer

Enable and start the monitoring service:

```bash
# Start the timer (runs every 5 minutes)
sudo systemctl start system-monitor.timer

# Enable timer to start on boot
sudo systemctl enable system-monitor.timer
```

### Check Timer Status

View the current status of the monitoring timer:

```bash
sudo systemctl status system-monitor.timer
```

### View Logs

Monitor real-time logs:

```bash
# Follow Telegram/Google Chat notifications and system information
sudo journalctl -u system-monitor.timer -f

# View system monitoring logs
tail -f /opt/monitoring/logs/monitoring.log

# View error logs
tail -f /opt/monitoring/logs/monitoring-error.log
```

### Test Manual Execution

To verify the configuration works correctly, run manually:

```bash
sudo /opt/monitoring/monitoring.sh
```

Check the logs to confirm:
```bash
tail -20 /opt/monitoring/logs/monitoring.log
```

## 📊 Monitoring Schedule

The systemd timer runs the monitoring script with the following schedule:

- **Initial execution**: 1 minute after boot
- **Recurring execution**: Every 5 minutes
- **Random delay**: 0-30 seconds (prevents simultaneous executions across multiple servers)
- **Persistent**: Timer state is preserved across reboots

View timer statistics:

```bash
sudo systemctl list-timers system-monitor.timer
```

## 🔍 Troubleshooting

### Check if timer is active

```bash
sudo systemctl is-active system-monitor.timer
```

### View timer details

```bash
sudo systemctl show system-monitor.timer
```

### Disable monitoring

```bash
sudo systemctl stop system-monitor.timer
sudo systemctl disable system-monitor.timer
```

### Check service execution history

```bash
sudo journalctl -u system-monitor.service --no-pager | tail -50
```

### Verify environment variables are loaded

```bash
sudo systemctl show-environment | grep -E "CPU_|MEMORY_|DISK_"
```

## 📝 Log Locations

- **Main log**: `/opt/monitoring/logs/monitoring.log`
- **Error log**: `/opt/monitoring/logs/monitoring-error.log`
- **Systemd journal**: `journalctl -u system-monitor.timer`

## 🔐 Security Considerations

- Configuration file is set to `600` (readable only by root)
- Service runs with root privileges
- Systemd sandboxing enabled (`ProtectSystem=strict`, `ProtectHome=yes`)
- Temporary files isolated (`PrivateTmp=yes`)

## 📋 File Structure

```
monitoring-bash/
├── monitoring.sh              # Main monitoring script
├── setup.sh                   # Installation script
├── config/
│   └── .env                   # Configuration file
├── systemd/
│   ├── system-monitor.service # Systemd service unit
│   └── system-monitor.timer   # Systemd timer unit
└── README.md                  # This file
```

## 🐛 Debug Mode

Enable detailed logging by setting `DEBUG=true` in `config/.env`:

```bash
echo "DEBUG=true" >> /opt/monitoring/config/.env
```

Then run:

```bash
sudo /opt/monitoring/monitoring.sh
```

Check verbose output:

```bash
tail -f /opt/monitoring/logs/monitoring.log
```

## 📧 Notification Examples

When a threshold is exceeded, you'll receive an alert containing:

- Server hostname
- Current timestamp
- System metrics (CPU, Memory, Disk percentages)
- Alert reasons with actual vs. threshold values
- Top 3 processes by memory usage
- Top 3 processes by CPU usage
- Configured thresholds

## 📄 License

This project is provided as-is for system administration purposes.

## ❓ Support

For issues or questions, review:
1. Configuration in `config/.env`
2. Logs in `/opt/monitoring/logs/`
3. Systemd journal: `sudo journalctl -u system-monitor.timer`
