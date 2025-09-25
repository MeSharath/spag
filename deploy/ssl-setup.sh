#!/bin/bash

# =============================================================================
# Studio Finder - SSL Setup Script
# =============================================================================
# This script sets up SSL certificates using Let's Encrypt
# Run this after deploy-app.sh if you have a domain name
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running as correct user
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

log "Starting SSL certificate setup..."

# Get domain name
DOMAIN_NAME=$(prompt "Enter your domain name (e.g., api.yourdomain.com)")
EMAIL=$(prompt "Enter your email for Let's Encrypt notifications")

# Validate inputs
if [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL" ]; then
    error "Domain name and email are required!"
fi

# Check if domain resolves to this server
log "Checking DNS resolution..."
DOMAIN_IP=$(dig +short $DOMAIN_NAME | tail -n1)
SERVER_IP=$(curl -s ifconfig.me)

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    warn "Domain $DOMAIN_NAME resolves to $DOMAIN_IP but server IP is $SERVER_IP"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Please update your DNS records to point $DOMAIN_NAME to $SERVER_IP"
    fi
fi

# Check if Certbot is installed
if ! command -v certbot &> /dev/null; then
    error "Certbot is not installed. Please run setup-server.sh first."
fi

# Stop nginx temporarily
log "Stopping Nginx temporarily..."
sudo systemctl stop nginx

# Obtain SSL certificate
log "Obtaining SSL certificate for $DOMAIN_NAME..."
sudo certbot certonly --standalone \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN_NAME

# Start nginx
sudo systemctl start nginx

# Update Nginx configuration for SSL
log "Updating Nginx configuration for SSL..."
sudo tee /etc/nginx/conf.d/studio-finder.conf > /dev/null << EOF
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Logging
    access_log /opt/studio-finder/logs/nginx-access.log;
    error_log /opt/studio-finder/logs/nginx-error.log;
    
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
        return 200 'Studio Finder API Server is running securely!';
        add_header Content-Type text/plain;
    }
}
EOF

# Test Nginx configuration
sudo nginx -t || error "Nginx configuration test failed"

# Reload Nginx
sudo systemctl reload nginx

# Set up automatic certificate renewal
log "Setting up automatic certificate renewal..."
(sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --nginx") | sudo crontab -

# Test SSL certificate
log "Testing SSL certificate..."
sleep 5

if curl -f -s "https://$DOMAIN_NAME/api/health" > /dev/null; then
    log "✅ SSL certificate is working correctly"
else
    error "❌ SSL certificate test failed"
fi

log "SSL setup completed successfully!"

echo -e "${BLUE}"
echo "=============================================="
echo "    SSL Certificate Setup Complete"
echo "=============================================="
echo ""
echo "🔒 HTTPS API Base URL: https://$DOMAIN_NAME/api"
echo "🏥 Health Check: https://$DOMAIN_NAME/api/health"
echo "🎵 Studios API: https://$DOMAIN_NAME/api/studios"
echo ""
echo "📱 Update Flutter app API URL to:"
echo "   https://$DOMAIN_NAME/api"
echo ""
echo "🔄 Certificate auto-renewal is set up"
echo "   Certificates will renew automatically"
echo ""
echo "🧪 Test certificate renewal:"
echo "   sudo certbot renew --dry-run"
echo "=============================================="
echo -e "${NC}"
