#!/bin/bash

# =============================================================================
# Studio Finder - Server-Specific Configuration
# =============================================================================
# Optimized for Ubuntu 22.04.5 LTS ARM64 (Neoverse-N1)
# Server IP: 10.0.0.156
# RAM: 11GB, CPU: 2 cores
# =============================================================================

set -e

# Server Configuration
SERVER_IP="10.0.0.156"
SERVER_OS="Ubuntu 22.04.5 LTS"
SERVER_ARCH="aarch64"
SERVER_RAM_GB="11"
SERVER_CPUS="2"

# Application Configuration
APP_DIR="/opt/studio-finder"
JAVA_HEAP_MIN="1024m"    # ~1GB for 11GB system
JAVA_HEAP_MAX="4096m"    # ~4GB max for 11GB system
NGINX_WORKER_PROCESSES="2"  # Match CPU count

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Optimize JVM for ARM64 and available resources
optimize_jvm_config() {
    log "Optimizing JVM configuration for ARM64..."
    
    # Create optimized environment file
    cat > "$APP_DIR/backend/.env" << EOF
# =============================================================================
# Studio Finder Backend - Environment Variables
# Optimized for Ubuntu 22.04.5 LTS ARM64 (Neoverse-N1)
# Server: 10.0.0.156, RAM: 11GB, CPU: 2 cores
# =============================================================================

# Spring Boot Configuration
SPRING_PROFILES_ACTIVE=prod

# Database Configuration (Supabase)
DATABASE_URL=jdbc:postgresql://db.schsrcjdukkduduueytz.supabase.co:5432/postgres
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=YOUR_SUPABASE_PASSWORD

# Server Configuration
SERVER_PORT=8080

# JVM Options - Optimized for ARM64 Neoverse-N1
JAVA_OPTS=-Xms${JAVA_HEAP_MIN} -Xmx${JAVA_HEAP_MAX} -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication -XX:+OptimizeStringConcat -XX:+UseCompressedOops -XX:+UseCompressedClassPointers -server

# Logging Configuration
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_SPAG_STUDIO=INFO

# Connection Pool Settings (optimized for 2 CPU cores)
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=10
SPRING_DATASOURCE_HIKARI_MINIMUM_IDLE=2
SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT=20000
SPRING_DATASOURCE_HIKARI_IDLE_TIMEOUT=300000
SPRING_DATASOURCE_HIKARI_MAX_LIFETIME=1200000

# Server Thread Pool (optimized for 2 cores)
SERVER_TOMCAT_THREADS_MAX=50
SERVER_TOMCAT_THREADS_MIN_SPARE=10
SERVER_TOMCAT_ACCEPT_COUNT=100
EOF
    
    chmod 600 "$APP_DIR/backend/.env"
    log "✅ JVM configuration optimized for ARM64"
}

# Optimize Nginx for ARM64 and 2 CPU cores
optimize_nginx_config() {
    log "Optimizing Nginx configuration..."
    
    # Create optimized Nginx configuration
    sudo tee /etc/nginx/conf.d/studio-finder.conf > /dev/null << EOF
# Studio Finder Nginx Configuration
# Optimized for Ubuntu 22.04.5 LTS ARM64 (Neoverse-N1)
# Server: 10.0.0.156, RAM: 11GB, CPU: 2 cores

server {
    listen 80;
    server_name 10.0.0.156;
    
    # Optimize for ARM64
    client_max_body_size 10M;
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml;
    
    # API routes
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Optimized proxy settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
        
        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Health check endpoint (no logging)
    location /api/health {
        proxy_pass http://127.0.0.1:8080/api/health;
        access_log off;
        proxy_connect_timeout 5s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
    }
    
    # Root endpoint
    location / {
        return 200 'Studio Finder API Server - Running on Ubuntu 22.04.5 LTS ARM64';
        add_header Content-Type text/plain;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
EOF
    
    # Update main Nginx configuration for ARM64 optimization
    sudo tee /etc/nginx/nginx.conf > /dev/null << EOF
user www-data;
worker_processes ${NGINX_WORKER_PROCESSES};
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # Basic Settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;
    
    # ARM64 specific optimizations
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging Settings
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;
    
    # Gzip Settings
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Virtual Host Configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Test and reload Nginx
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "✅ Nginx configuration optimized for ARM64"
    else
        error "❌ Nginx configuration test failed"
    fi
}

# Create systemd service optimized for ARM64
create_systemd_service() {
    log "Creating optimized systemd service..."
    
    sudo tee /etc/systemd/system/studio-finder.service > /dev/null << EOF
[Unit]
Description=Studio Finder Spring Boot Application
After=network.target
Wants=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/opt/studio-finder/backend
ExecStart=/usr/bin/java -jar /opt/studio-finder/backend/target/studio-backend-0.0.1-SNAPSHOT.jar
EnvironmentFile=/opt/studio-finder/backend/.env
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=studio-finder

# Resource limits for 11GB RAM system
MemoryMax=6G
MemoryHigh=5G

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/studio-finder

# Process settings optimized for 2 CPU cores
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable studio-finder
    log "✅ Systemd service created and enabled"
}

# Set up system monitoring for ARM64
setup_monitoring() {
    log "Setting up ARM64-specific monitoring..."
    
    # Create monitoring script for ARM64
    cat > "$APP_DIR/monitor-arm64.sh" << 'EOF'
#!/bin/bash

# ARM64 System Monitoring for Studio Finder
echo "=== Studio Finder ARM64 System Status ==="
echo "Server: 10.0.0.156 (Ubuntu 22.04.5 LTS)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo ""

# CPU Information
echo "=== CPU (Neoverse-N1) ==="
grep "model name" /proc/cpuinfo | head -1
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

# Memory Information
echo "=== Memory (11GB Total) ==="
free -h | grep -E "^Mem|^Swap"
echo ""

# Disk Information
echo "=== Disk Usage ==="
df -h / | tail -1
echo ""

# Service Status
echo "=== Service Status ==="
systemctl is-active studio-finder && echo "Studio Finder: RUNNING" || echo "Studio Finder: STOPPED"
systemctl is-active nginx && echo "Nginx: RUNNING" || echo "Nginx: STOPPED"
echo ""

# Network
echo "=== Network ==="
ss -tuln | grep -E ":80|:443|:8080"
echo ""

# Java Process
echo "=== Java Process ==="
ps aux | grep java | grep -v grep | head -1
EOF
    
    chmod +x "$APP_DIR/monitor-arm64.sh"
    log "✅ ARM64 monitoring script created"
}

# Display server information
show_server_info() {
    log "Server Configuration Summary:"
    
    echo -e "${BLUE}"
    echo "=============================================="
    echo "    Studio Finder Server Configuration"
    echo "=============================================="
    echo "Server IP:      $SERVER_IP"
    echo "OS:             $SERVER_OS"
    echo "Architecture:   $SERVER_ARCH (Neoverse-N1)"
    echo "RAM:            ${SERVER_RAM_GB}GB"
    echo "CPU Cores:      $SERVER_CPUS"
    echo ""
    echo "JVM Configuration:"
    echo "  Min Heap:     $JAVA_HEAP_MIN"
    echo "  Max Heap:     $JAVA_HEAP_MAX"
    echo "  GC:           G1GC (optimized for ARM64)"
    echo ""
    echo "Nginx Configuration:"
    echo "  Worker Processes: $NGINX_WORKER_PROCESSES"
    echo "  Gzip:            Enabled"
    echo "  ARM64 Optimized: Yes"
    echo ""
    echo "API Endpoints:"
    echo "  Health:       http://$SERVER_IP/api/health"
    echo "  Studios:      http://$SERVER_IP/api/studios"
    echo ""
    echo "Management:"
    echo "  Monitor:      $APP_DIR/monitor-arm64.sh"
    echo "  Logs:         journalctl -u studio-finder -f"
    echo "=============================================="
    echo -e "${NC}"
}

# Main execution
main() {
    log "Configuring Studio Finder for Ubuntu 22.04.5 LTS ARM64..."
    
    # Create directories
    mkdir -p "$APP_DIR/backend"
    mkdir -p "$APP_DIR/logs"
    mkdir -p "$APP_DIR/config"
    
    optimize_jvm_config
    optimize_nginx_config
    create_systemd_service
    setup_monitoring
    show_server_info
    
    log "✅ Server-specific configuration completed!"
}

# Check if running on correct server
if [ "$(hostname -I | awk '{print $1}')" != "$SERVER_IP" ]; then
    warn "This script is optimized for server IP $SERVER_IP"
    warn "Current server IP: $(hostname -I | awk '{print $1}')"
    read -p "Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Run main function
main "$@"
