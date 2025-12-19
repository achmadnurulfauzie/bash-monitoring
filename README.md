# System Monitoring Script dengan Notifikasi

Script bash untuk monitoring CPU, Memory, Disk dengan notifikasi otomatis ke Telegram atau Google Chat.

## 📋 Fitur

✅ Monitor CPU Usage  
✅ Monitor Memory Usage  
✅ Monitor Disk Usage  
✅ Tampilkan Top 3 Proses (Memory)  
✅ Tampilkan Top 3 Proses (CPU)  
✅ Notifikasi ke Telegram  
✅ Notifikasi ke Google Chat  
✅ Threshold yang dapat dikonfigurasi  
✅ Logging detail  
✅ Berjalan di Systemd Timer  

## 🔧 Prasyarat

- Ubuntu/Debian Linux
- `curl` untuk HTTP requests
- `top` dan `ps` utilities (sudah tersedia di kebanyakan distro)
- Akses internet untuk notifikasi

## 📦 Instalasi

### 1. Clone atau Download Files

```bash
git clone https://github.com/your-repo/system-monitoring.git
cd system-monitoring
