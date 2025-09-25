#!/bin/bash

# =============================================================================
# Studio Finder - Advanced Health Monitoring
# =============================================================================
# This script provides comprehensive health monitoring with alerts
# =============================================================================

set -e

# Configuration
APP_DIR="/opt/studio-finder"
SERVICE_NAME="studio-finder"
LOG_DIR="$APP_DIR/logs"
ALERT_EMAIL="admin@yourdomain.com"  # UPDATE THIS
SLACK_WEBHOOK=""  # Optional: Add your Slack webhook URL

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
RESPONSE_TIME_THRESHOLD=5000  # milliseconds

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Send alert function
send_alert() {
    local subject="$1"
    local message="$2"
    local severity="$3"
    
    # Email alert
    if command -v mail &> /dev/null && [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "[$severity] Studio Finder: $subject" "$ALERT_EMAIL"
    fi
    
    # Slack alert
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 [$severity] Studio Finder: $subject\n$message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || true
    fi
    
    # Log alert
    echo "[$(date)] ALERT [$severity] $subject: $message" >> "$LOG_DIR/alerts.log"
}

# Check service status
check_service() {
    if ! systemctl is-active --quiet $SERVICE_NAME; then
        error "Service $SERVICE_NAME is not running"
        send_alert "Service Down" "Studio Finder service is not running" "CRITICAL"
        
        # Attempt restart
        log "Attempting to restart service..."
        sudo systemctl start $SERVICE_NAME
        sleep 10
        
        if systemctl is-active --quiet $SERVICE_NAME; then
            log "Service restarted successfully"
            send_alert "Service Recovered" "Studio Finder service was restarted automatically" "INFO"
        else
            send_alert "Service Restart Failed" "Failed to restart Studio Finder service" "CRITICAL"
            return 1
        fi
    fi
    return 0
}

# Check API health
check_api() {
    local start_time=$(date +%s%3N)
    
    if ! curl -f -s "http://localhost/api/health" > /dev/null; then
        error "API health check failed"
        send_alert "API Down" "Studio Finder API is not responding" "CRITICAL"
        return 1
    fi
    
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    if [ $response_time -gt $RESPONSE_TIME_THRESHOLD ]; then
        warn "API response time is slow: ${response_time}ms"
        send_alert "Slow Response" "API response time: ${response_time}ms (threshold: ${RESPONSE_TIME_THRESHOLD}ms)" "WARNING"
    fi
    
    return 0
}

# Check database connectivity
check_database() {
    if ! curl -f -s "http://localhost/api/studios" > /dev/null; then
        error "Database connectivity check failed"
        send_alert "Database Issue" "Cannot connect to database or retrieve studios" "CRITICAL"
        return 1
    fi
    return 0
}

# Check system resources
check_resources() {
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    cpu_usage=${cpu_usage%.*}  # Remove decimal
    
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        warn "High CPU usage: ${cpu_usage}%"
        send_alert "High CPU Usage" "CPU usage is ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)" "WARNING"
    fi
    
    # Memory usage
    local memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    
    if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        warn "High memory usage: ${memory_usage}%"
        send_alert "High Memory Usage" "Memory usage is ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)" "WARNING"
    fi
    
    # Disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        warn "High disk usage: ${disk_usage}%"
        send_alert "High Disk Usage" "Disk usage is ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)" "WARNING"
    fi
}

# Check log errors
check_logs() {
    local error_count=$(tail -100 "$LOG_DIR/studio-finder.log" 2>/dev/null | grep -i "error\|exception\|failed" | wc -l)
    
    if [ "$error_count" -gt 5 ]; then
        warn "High error count in logs: $error_count errors in last 100 lines"
        send_alert "High Error Rate" "Found $error_count errors in recent logs" "WARNING"
    fi
}

# Check SSL certificate expiry
check_ssl() {
    if [ -f "/etc/letsencrypt/live/*/cert.pem" ]; then
        local cert_file=$(ls /etc/letsencrypt/live/*/cert.pem | head -1)
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
        
        if [ "$days_until_expiry" -lt 30 ]; then
            warn "SSL certificate expires in $days_until_expiry days"
            send_alert "SSL Certificate Expiring" "SSL certificate expires in $days_until_expiry days" "WARNING"
        fi
    fi
}

# Main monitoring function
main() {
    log "Starting health monitoring check..."
    
    local issues=0
    
    # Run all checks
    check_service || ((issues++))
    check_api || ((issues++))
    check_database || ((issues++))
    check_resources
    check_logs
    check_ssl
    
    # Summary
    if [ $issues -eq 0 ]; then
        log "✅ All health checks passed"
        echo "$(date): All checks passed" >> "$LOG_DIR/health-check.log"
    else
        error "❌ $issues critical issues found"
        echo "$(date): $issues critical issues found" >> "$LOG_DIR/health-check.log"
        exit 1
    fi
}

# Run monitoring
main "$@"
