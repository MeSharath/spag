#!/bin/bash

# =============================================================================
# Studio Finder - Application Management Script
# =============================================================================
# This script provides easy management commands for the deployed application
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/studio-finder"
SERVICE_NAME="studio-finder"
LOG_DIR="$APP_DIR/logs"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Function to show usage
show_usage() {
    echo -e "${BLUE}Studio Finder Application Management${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start       Start the application"
    echo "  stop        Stop the application"
    echo "  restart     Restart the application"
    echo "  status      Show application status"
    echo "  logs        Show application logs"
    echo "  logs-live   Show live application logs"
    echo "  health      Check application health"
    echo "  update      Update application from git"
    echo "  backup      Create backup of current deployment"
    echo "  rollback    Rollback to previous backup"
    echo "  monitor     Show monitoring information"
    echo "  cleanup     Clean old logs and backups"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 logs-live"
    echo "  $0 restart"
}

# Function to check service status
check_status() {
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Service is running${NC}"
        systemctl status $SERVICE_NAME --no-pager -l
    else
        echo -e "${RED}❌ Service is not running${NC}"
        systemctl status $SERVICE_NAME --no-pager -l
    fi
}

# Function to check application health
check_health() {
    log "Checking application health..."
    
    # Check service status
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Service Status: Running${NC}"
    else
        echo -e "${RED}❌ Service Status: Not Running${NC}"
        return 1
    fi
    
    # Check API health
    if curl -f -s "http://localhost:8080/api/health" > /dev/null; then
        echo -e "${GREEN}✅ API Health: OK${NC}"
    else
        echo -e "${RED}❌ API Health: Failed${NC}"
        return 1
    fi
    
    # Check through Nginx
    if curl -f -s "http://localhost/api/health" > /dev/null; then
        echo -e "${GREEN}✅ Nginx Proxy: OK${NC}"
    else
        echo -e "${RED}❌ Nginx Proxy: Failed${NC}"
        return 1
    fi
    
    # Check database connection
    if curl -f -s "http://localhost/api/studios" > /dev/null; then
        echo -e "${GREEN}✅ Database Connection: OK${NC}"
    else
        echo -e "${YELLOW}⚠️  Database Connection: Warning${NC}"
    fi
    
    # Show resource usage
    echo ""
    echo -e "${BLUE}Resource Usage:${NC}"
    echo "Memory: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2 }')"
    echo "Disk: $(df -h / | awk 'NR==2{print $5}')"
    echo "Load: $(uptime | awk -F'load average:' '{ print $2 }')"
}

# Function to update application
update_app() {
    log "Updating application..."
    
    # Create backup first
    create_backup
    
    # Stop service
    log "Stopping service..."
    sudo systemctl stop $SERVICE_NAME
    
    # Update code
    cd $APP_DIR
    if [ -d ".git" ]; then
        log "Pulling latest code..."
        git pull origin main || git pull origin master
    else
        error "No git repository found. Please update code manually."
        return 1
    fi
    
    # Build application
    cd $APP_DIR/backend
    log "Building application..."
    ./mvnw clean package -DskipTests
    
    # Start service
    log "Starting service..."
    sudo systemctl start $SERVICE_NAME
    
    # Wait and check health
    sleep 10
    check_health
}

# Function to create backup
create_backup() {
    log "Creating backup..."
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$APP_DIR/backup/$BACKUP_NAME"
    
    if [ -f "$APP_DIR/backend/target/studio-backend-0.0.1-SNAPSHOT.jar" ]; then
        cp -r "$APP_DIR/backend" "$APP_DIR/backup/$BACKUP_NAME/"
        log "Backup created: $APP_DIR/backup/$BACKUP_NAME"
    else
        warn "No JAR file found to backup"
    fi
}

# Function to rollback to previous backup
rollback() {
    log "Rolling back to previous backup..."
    
    LATEST_BACKUP=$(ls -t $APP_DIR/backup/ | head -n1)
    if [ -z "$LATEST_BACKUP" ]; then
        error "No backups found"
        return 1
    fi
    
    log "Rolling back to: $LATEST_BACKUP"
    
    # Stop service
    sudo systemctl stop $SERVICE_NAME
    
    # Restore backup
    cp -r "$APP_DIR/backup/$LATEST_BACKUP/backend/"* "$APP_DIR/backend/"
    
    # Start service
    sudo systemctl start $SERVICE_NAME
    
    log "Rollback completed"
    sleep 5
    check_health
}

# Function to show monitoring info
show_monitor() {
    echo -e "${BLUE}Studio Finder Monitoring Dashboard${NC}"
    echo "=================================="
    
    # Service status
    echo ""
    echo -e "${BLUE}Service Status:${NC}"
    check_status
    
    echo ""
    echo -e "${BLUE}Recent Logs (last 10 lines):${NC}"
    sudo journalctl -u $SERVICE_NAME -n 10 --no-pager
    
    echo ""
    echo -e "${BLUE}API Endpoints:${NC}"
    echo "Health: curl http://localhost/api/health"
    echo "Studios: curl http://localhost/api/studios"
    
    echo ""
    echo -e "${BLUE}Log Files:${NC}"
    echo "Application: $LOG_DIR/studio-finder.log"
    echo "Nginx Access: $LOG_DIR/nginx-access.log"
    echo "Nginx Error: $LOG_DIR/nginx-error.log"
}

# Function to cleanup old files
cleanup() {
    log "Cleaning up old files..."
    
    # Clean old backups (keep last 5)
    cd $APP_DIR/backup
    ls -t | tail -n +6 | xargs -r rm -rf
    log "Cleaned old backups"
    
    # Clean old logs (older than 30 days)
    find $LOG_DIR -name "*.log.*" -mtime +30 -delete
    log "Cleaned old log files"
    
    # Clean Maven cache
    cd $APP_DIR/backend
    ./mvnw clean
    log "Cleaned Maven cache"
    
    log "Cleanup completed"
}

# Main script logic
case "$1" in
    start)
        log "Starting $SERVICE_NAME..."
        sudo systemctl start $SERVICE_NAME
        sleep 3
        check_status
        ;;
    stop)
        log "Stopping $SERVICE_NAME..."
        sudo systemctl stop $SERVICE_NAME
        check_status
        ;;
    restart)
        log "Restarting $SERVICE_NAME..."
        sudo systemctl restart $SERVICE_NAME
        sleep 5
        check_status
        ;;
    status)
        check_status
        ;;
    logs)
        sudo journalctl -u $SERVICE_NAME --no-pager
        ;;
    logs-live)
        log "Showing live logs (Ctrl+C to exit)..."
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    health)
        check_health
        ;;
    update)
        update_app
        ;;
    backup)
        create_backup
        ;;
    rollback)
        rollback
        ;;
    monitor)
        show_monitor
        ;;
    cleanup)
        cleanup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
