#!/bin/bash

##############################################################################
# System Monitoring Script dengan Notifikasi ke Telegram/Google Chat
# Deskripsi: Monitor CPU, Memory, Disk dan kirim alert jika melebihi threshold
# Author: System Admin
# Version: 1.0
##############################################################################

set -euo pipefail

# ==================== KONFIGURASI ====================
# Load configuration dari .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] File konfigurasi tidak ditemukan: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Validasi variabel wajib
REQUIRED_VARS=("NOTIFICATION_TYPE" "CPU_THRESHOLD" "MEMORY_THRESHOLD" "DISK_THRESHOLD" "ALERT_TITLE")
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        echo "[ERROR] Variabel wajib tidak dikonfigurasi: $var"
        exit 1
    fi
done

# ==================== VARIABEL LOGGING ====================
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/monitoring.log"
ERROR_LOG="${LOG_DIR}/monitoring-error.log"
HOSTNAME_VAR=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Buat direktori logs jika belum ada
mkdir -p "$LOG_DIR"

# ==================== FUNGSI LOGGING ====================
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" | tee -a "$ERROR_LOG"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*" | tee -a "$LOG_FILE"
    fi
}

# ==================== FUNGSI UTILITY ====================

# Fungsi untuk mendapatkan persentase CPU
# get_cpu_usage() {
#     # Method: menggunakan top dengan interval 1 detik
#     top -bn2 -d 0.5 | grep "Cpu(s)" | tail -n1 | awk '{print int(100 - $8)}'
# }
get_cpu_usage() {
    local stat1=$(awk '/^cpu / {print $2, $4, $5}' /proc/stat)
    sleep 0.5
    local stat2=$(awk '/^cpu / {print $2, $4, $5}' /proc/stat)
    
    local user1=$(echo "$stat1" | awk '{print $1}')
    local system1=$(echo "$stat1" | awk '{print $2}')
    local idle1=$(echo "$stat1" | awk '{print $3}')
    
    local user2=$(echo "$stat2" | awk '{print $1}')
    local system2=$(echo "$stat2" | awk '{print $2}')
    local idle2=$(echo "$stat2" | awk '{print $3}')
    
    local total1=$((user1 + system1 + idle1))
    local total2=$((user2 + system2 + idle2))
    
    local total_diff=$((total2 - total1))
    local idle_diff=$((idle2 - idle1))
    
    if [[ $total_diff -gt 0 ]]; then
        local cpu_usage=$(( 100 * (total_diff - idle_diff) / total_diff ))
        echo "$cpu_usage"
    else
        echo "0"
    fi
}
# Fungsi untuk mendapatkan persentase Memory
get_memory_usage() {
    free | grep "^Mem" | awk '{printf "%.0f\n", ($3/$2) * 100}'
}

# Fungsi untuk mendapatkan persentase Disk pada root filesystem
get_disk_usage() {
    df / | tail -n1 | awk '{print $5}' | sed 's/%//'
}

# Fungsi untuk mendapatkan 3 proses dengan memory tertinggi
get_top_memory_processes() {
    ps aux --sort=-%mem | head -n 4 | tail -n 3 | \
    awk '{printf "  • %s (PID: %d) - %.2f%% (%.0fMB)\n", $11, $2, $4, $6/1024}' || \
    echo "  • Tidak ada data tersedia"
}

# Fungsi untuk mendapatkan 3 proses dengan CPU tertinggi
get_top_cpu_processes() {
    ps aux --sort=-%cpu | head -n 4 | tail -n 3 | \
    awk '{printf "  • %s (PID: %d) - %.2f%%\n", $11, $2, $3}' || \
    echo "  • Tidak ada data tersedia"
}

# ==================== FUNGSI NOTIFIKASI ====================

# Fungsi mengirim notifikasi ke Telegram
send_telegram_notification() {
    local message="$1"
    
    if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]] || [[ -z "${TELEGRAM_CHAT_ID:-}" ]]; then
        log_error "Telegram belum dikonfigurasi (TELEGRAM_BOT_TOKEN atau TELEGRAM_CHAT_ID kosong)"
        return 1
    fi
    
    local telegram_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    
    local response=$(curl -s -X POST "$telegram_url" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": \"$message\", \"parse_mode\": \"HTML\"}" \
        2>&1)
    
    if echo "$response" | grep -q '"ok":true'; then
        log_info "Notifikasi Telegram berhasil dikirim"
        return 0
    else
        log_error "Gagal mengirim notifikasi Telegram: $response"
        return 1
    fi
}

# Fungsi mengirim notifikasi ke Google Chat
send_google_chat_notification() {
    local message="$1"
    
    if [[ -z "${GOOGLE_CHAT_WEBHOOK_URL:-}" ]]; then
        log_error "Google Chat belum dikonfigurasi (GOOGLE_CHAT_WEBHOOK_URL kosong)"
        return 1
    fi
    
    # Format pesan untuk Google Chat (menggunakan card format)
    local json_payload=$(cat <<EOF
{
  "text": "$message"
}
EOF
)
    
    local response=$(curl -s -X POST "${GOOGLE_CHAT_WEBHOOK_URL}" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        2>&1)
    
    if echo "$response" | grep -q '"name"'; then
        log_info "Notifikasi Google Chat berhasil dikirim"
        return 0
    else
        log_error "Gagal mengirim notifikasi Google Chat: $response"
        return 1
    fi
}

# Fungsi wrapper untuk mengirim notifikasi
send_notification() {
    local message="$1"
    
    case "${NOTIFICATION_TYPE,,}" in
        telegram)
            send_telegram_notification "$message"
            ;;
        google_chat)
            send_google_chat_notification "$message"
            ;;
        both)
            send_telegram_notification "$message"
            send_google_chat_notification "$message"
            ;;
        *)
            log_error "Tipe notifikasi tidak valid: $NOTIFICATION_TYPE"
            return 1
            ;;
    esac
}

# ==================== FUNGSI PEMBUAT PESAN ====================

create_alert_message() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local disk_usage="$3"
    local alert_reasons="$4"
    
    local message="🚨 <b>SYSTEM ALERT - $ALERT_TITLE</b> 🚨
    
<b>Host:</b> <code>$HOSTNAME_VAR</code>
<b>Waktu:</b> <code>$TIMESTAMP</code>

<b>📊 STATUS SISTEM:</b>
• CPU: <code>${cpu_usage}%</code>
• Memory: <code>${memory_usage}%</code>
• Disk: <code>${disk_usage}%</code>

<b>⚠️ ALASAN ALERT:</b>
$alert_reasons

<b>🔴 TOP 3 PROSES (Memory):</b>
$(get_top_memory_processes)

<b>🔴 TOP 3 PROSES (CPU):</b>
$(get_top_cpu_processes)

<b>Threshold yang Diatur:</b>
• CPU: ${CPU_THRESHOLD}%
• Memory: ${MEMORY_THRESHOLD}%
• Disk: ${DISK_THRESHOLD}%
"
    
    echo "$message"
}

# ==================== FUNGSI MONITORING ====================

check_thresholds() {
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    local alert_triggered=false
    local alert_reasons=""
    
    log_debug "CPU Usage: ${cpu_usage}% (Threshold: ${CPU_THRESHOLD}%)"
    log_debug "Memory Usage: ${memory_usage}% (Threshold: ${MEMORY_THRESHOLD}%)"
    log_debug "Disk Usage: ${disk_usage}% (Threshold: ${DISK_THRESHOLD}%)"
    
    # Check CPU
    if (( cpu_usage >= CPU_THRESHOLD )); then
        alert_triggered=true
        alert_reasons+="• ❌ CPU melebihi threshold: ${cpu_usage}% ≥ ${CPU_THRESHOLD}%\n"
    fi
    
    # Check Memory
    if (( memory_usage >= MEMORY_THRESHOLD )); then
        alert_triggered=true
        alert_reasons+="• ❌ Memory melebihi threshold: ${memory_usage}% ≥ ${MEMORY_THRESHOLD}%\n"
    fi
    
    # Check Disk
    if (( disk_usage >= DISK_THRESHOLD )); then
        alert_triggered=true
        alert_reasons+="• ❌ Disk melebihi threshold: ${disk_usage}% ≥ ${DISK_THRESHOLD}%\n"
    fi
    
    # Jika ada threshold yang terlampaui, kirim notifikasi
    if $alert_triggered; then
        log_info "Alert terdeteksi! CPU: ${cpu_usage}%, Memory: ${memory_usage}%, Disk: ${disk_usage}%"
        
        local message=$(create_alert_message "$cpu_usage" "$memory_usage" "$disk_usage" "$alert_reasons")
        
        if send_notification "$message"; then
            log_info "Notifikasi alert berhasil dikirim"
        else
            log_error "Gagal mengirim notifikasi alert"
        fi
    else
        log_debug "✅ Semua metrik dalam kondisi normal"
    fi
}

# ==================== MAIN EXECUTION ====================

main() {
    log_info "=========================================="
    log_info "Memulai system monitoring check"
    log_info "Notification Type: $NOTIFICATION_TYPE"
    log_info "CPU Threshold: $CPU_THRESHOLD%"
    log_info "Memory Threshold: $MEMORY_THRESHOLD%"
    log_info "Disk Threshold: $DISK_THRESHOLD%"
    log_info "=========================================="
    
    check_thresholds
    
    log_info "Monitoring check selesai"
}

# Jalankan main function
main "$@"
