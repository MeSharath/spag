#!/bin/bash

# =============================================================================
# Studio Finder - Quick Deployment Script
# =============================================================================
# This script runs the complete deployment process in the correct order
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running on Oracle server
if [ ! -f "/etc/oracle-release" ] && [ ! -f "/etc/redhat-release" ] && [ ! -f "/etc/os-release" ]; then
    error "This script should be run on your Oracle server, not locally"
fi

log "🚀 Starting Studio Finder Quick Deployment"

# Make all scripts executable
log "Making deployment scripts executable..."
chmod +x deploy/*.sh
find deploy -name "*.sh" -exec chmod +x {} \;

# Step 1: Server Setup
log "📦 Step 1: Setting up server dependencies..."
if ! ./deploy/setup-server.sh; then
    error "Server setup failed"
fi

# Step 2: ARM64 Server Optimization
log "⚡ Step 2: Optimizing server for ARM64 (Ubuntu 22.04.5)..."
if ! ./deploy/server-config.sh; then
    error "Server optimization failed"
fi

# Step 3: Supabase Configuration
log "🗄️ Step 3: Configuring Supabase database..."
if ! ./deploy/setup-supabase.sh; then
    error "Supabase setup failed"
fi

# Step 4: Application Deployment
log "🚀 Step 4: Deploying application..."
if ! ./deploy/deploy-app.sh; then
    error "Application deployment failed"
fi

# Step 5: Verification
log "✅ Step 5: Verifying deployment..."
sleep 10

# Test health endpoint
if curl -f -s "http://localhost/api/health" > /dev/null; then
    log "✅ Health check passed"
else
    error "❌ Health check failed"
fi

# Test studios API
if curl -f -s "http://localhost/api/studios" > /dev/null; then
    log "✅ Studios API working"
else
    log "⚠️ Studios API test failed (may be normal if database is still initializing)"
fi

log "🎉 Studio Finder deployment completed successfully!"

echo -e "${BLUE}"
echo "=============================================="
echo "    🎉 DEPLOYMENT COMPLETE! 🎉"
echo "=============================================="
echo ""
echo "🌐 Your API is running at:"
echo "   Health: http://$(curl -s ifconfig.me)/api/health"
echo "   Studios: http://$(curl -s ifconfig.me)/api/studios"
echo ""
echo "🔧 Management Commands:"
echo "   ./deploy/manage-app.sh status"
echo "   ./deploy/manage-app.sh logs-live"
echo "   ./deploy/monitoring/performance-dashboard.sh"
echo ""
echo "📱 Update your Flutter app API URL to:"
echo "   http://$(curl -s ifconfig.me)/api"
echo ""
echo "🔒 Optional: Set up SSL with:"
echo "   ./deploy/ssl-setup.sh"
echo "=============================================="
echo -e "${NC}"
