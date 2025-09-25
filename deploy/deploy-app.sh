#!/bin/bash

# =============================================================================
# Studio Finder - Application Deployment Script
# =============================================================================
# This script deploys the Studio Finder application to your Oracle server
# Make sure to run setup-server.sh first
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/opt/studio-finder"
SERVICE_NAME="studio-finder"
BACKUP_DIR="$APP_DIR/backup"
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
    exit 1
}

# Function to prompt for user input
prompt() {
    read -p "$1: " value
    echo $value
}

# Function to prompt for password (hidden input)
prompt_password() {
    read -s -p "$1: " value
    echo
    echo $value
}

# Check if running as correct user
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

log "Starting Studio Finder application deployment..."

# Check if app directory exists
if [ ! -d "$APP_DIR" ]; then
    error "Application directory $APP_DIR does not exist. Please run setup-server.sh first."
fi

# Get Supabase credentials
echo -e "${BLUE}Please provide your Supabase database credentials:${NC}"
SUPABASE_HOST=$(prompt "Supabase Host (e.g., db.xxxxx.supabase.co)")
SUPABASE_PASSWORD=$(prompt_password "Supabase Password")
SERVER_IP=$(prompt "Your Oracle Server IP Address")
DOMAIN_NAME=$(prompt "Domain name (optional, press Enter to skip)")

# Validate inputs
if [ -z "$SUPABASE_HOST" ] || [ -z "$SUPABASE_PASSWORD" ] || [ -z "$SERVER_IP" ]; then
    error "Supabase host, password, and server IP are required!"
fi

# Create backup of existing deployment (if exists)
if [ -f "$APP_DIR/backend/target/studio-backend-0.0.1-SNAPSHOT.jar" ]; then
    log "Creating backup of existing deployment..."
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    cp -r "$APP_DIR/backend" "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || true
    log "Backup created: $BACKUP_DIR/$BACKUP_NAME"
fi

# Stop existing service (if running)
if systemctl is-active --quiet $SERVICE_NAME; then
    log "Stopping existing $SERVICE_NAME service..."
    sudo systemctl stop $SERVICE_NAME
fi

# Clone or update repository
log "Updating application code..."
cd $APP_DIR

if [ -d ".git" ]; then
    log "Updating existing repository..."
    git pull origin main || git pull origin master
else
    log "Repository not found. Please upload your code to $APP_DIR"
    log "You can use: scp -r /path/to/your/code/* user@$SERVER_IP:$APP_DIR/"
    read -p "Press Enter after uploading your code..."
fi

# Navigate to backend directory
cd $APP_DIR/backend

# Make Maven wrapper executable
chmod +x mvnw

# Build the application
log "Building application..."
./mvnw clean package -DskipTests

# Verify JAR was created
if [ ! -f "target/studio-backend-0.0.1-SNAPSHOT.jar" ]; then
    error "JAR file not found. Build may have failed."
fi

log "Application built successfully"

# Create environment configuration
log "Creating environment configuration..."
cat > $APP_DIR/backend/.env << EOF
SPRING_PROFILES_ACTIVE=prod
DATABASE_URL=jdbc:postgresql://$SUPABASE_HOST:5432/postgres
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=$SUPABASE_PASSWORD
SERVER_PORT=8080
JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC
EOF

# Set proper permissions
chmod 600 $APP_DIR/backend/.env

# Create systemd service file
log "Creating systemd service..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=Studio Finder Backend API
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR/backend
ExecStart=/usr/bin/java \$JAVA_OPTS -jar target/studio-backend-0.0.1-SNAPSHOT.jar
EnvironmentFile=$APP_DIR/backend/.env
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Logging
StandardOutput=append:$LOG_DIR/studio-finder.log
StandardError=append:$LOG_DIR/studio-finder-error.log

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$APP_DIR $LOG_DIR

[Install]
WantedBy=multi-user.target
EOF

# Create Nginx configuration
log "Configuring Nginx..."
if [ -n "$DOMAIN_NAME" ]; then
    SERVER_NAME="$DOMAIN_NAME"
else
    SERVER_NAME="$SERVER_IP"
fi

sudo tee /etc/nginx/conf.d/studio-finder.conf > /dev/null << EOF
server {
    listen 80;
    server_name $SERVER_NAME;
    
    # Logging
    access_log $LOG_DIR/nginx-access.log;
    error_log $LOG_DIR/nginx-error.log;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # CORS headers for Flutter app
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
        
        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Origin, Content-Type, Accept, Authorization" always;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 200;
        }
    }
    
    # Health check
    location /health {
        proxy_pass http://localhost:8080/api/health;
        access_log off;
    }
    
    # Root location
    location / {
        return 200 'Studio Finder API Server is running!';
        add_header Content-Type text/plain;
    }
}
EOF

# Test Nginx configuration
sudo nginx -t || error "Nginx configuration test failed"

# Reload systemd and start services
log "Starting services..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
sudo systemctl reload nginx

# Wait for service to start
sleep 5

# Check service status
if systemctl is-active --quiet $SERVICE_NAME; then
    log "✅ $SERVICE_NAME service is running"
else
    error "❌ $SERVICE_NAME service failed to start. Check logs: sudo journalctl -u $SERVICE_NAME -f"
fi

# Test the deployment
log "Testing deployment..."
sleep 10

# Test health endpoint
if curl -f -s "http://localhost:8080/api/health" > /dev/null; then
    log "✅ Backend health check passed"
else
    error "❌ Backend health check failed"
fi

# Test through Nginx
if curl -f -s "http://localhost/api/health" > /dev/null; then
    log "✅ Nginx proxy health check passed"
else
    error "❌ Nginx proxy health check failed"
fi

# Test studios endpoint
if curl -f -s "http://localhost/api/studios" > /dev/null; then
    log "✅ Studios API endpoint is working"
else
    warn "⚠️  Studios API endpoint test failed (this might be normal if database is not set up)"
fi

# Create monitoring script
log "Creating monitoring script..."
cat > $APP_DIR/monitor.sh << 'EOF'
#!/bin/bash
# Studio Finder Monitoring Script

SERVICE_NAME="studio-finder"
API_URL="http://localhost/api/health"

# Check service status
if ! systemctl is-active --quiet $SERVICE_NAME; then
    echo "❌ Service $SERVICE_NAME is not running"
    sudo systemctl start $SERVICE_NAME
    exit 1
fi

# Check API health
if ! curl -f -s "$API_URL" > /dev/null; then
    echo "❌ API health check failed"
    exit 1
fi

echo "✅ All checks passed"
EOF

chmod +x $APP_DIR/monitor.sh

# Set up cron job for monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * $APP_DIR/monitor.sh >> $LOG_DIR/monitor.log 2>&1") | crontab -

log "Deployment completed successfully!"

echo -e "${BLUE}"
echo "=============================================="
echo "    Studio Finder Deployment Complete"
echo "=============================================="
echo ""
echo "🌐 API Base URL: http://$SERVER_NAME/api"
echo "🏥 Health Check: http://$SERVER_NAME/api/health"
echo "🎵 Studios API: http://$SERVER_NAME/api/studios"
echo ""
echo "📊 Service Status:"
echo "   sudo systemctl status studio-finder"
echo ""
echo "📝 View Logs:"
echo "   sudo journalctl -u studio-finder -f"
echo "   tail -f $LOG_DIR/studio-finder.log"
echo ""
echo "🔧 Manage Service:"
echo "   sudo systemctl start/stop/restart studio-finder"
echo ""
if [ -n "$DOMAIN_NAME" ]; then
echo "🔒 Set up SSL (optional):"
echo "   sudo certbot --nginx -d $DOMAIN_NAME"
echo ""
fi
echo "📱 Update Flutter app API URL to:"
echo "   http://$SERVER_NAME/api"
echo "=============================================="
echo -e "${NC}"
