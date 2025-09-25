#!/bin/bash

# =============================================================================
# Studio Finder - Server Setup Script
# =============================================================================
# This script sets up the Oracle server with all required dependencies
# Run this script first on your Oracle server
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

log "Starting Studio Finder server setup..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    error "Cannot detect OS version"
fi

log "Detected OS: $OS $VER"

# Update system packages
log "Updating system packages..."
if [[ "$OS" == *"Oracle"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"CentOS"* ]]; then
    sudo yum update -y
    PACKAGE_MANAGER="yum"
elif [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
    sudo apt update && sudo apt upgrade -y
    PACKAGE_MANAGER="apt"
else
    error "Unsupported operating system: $OS"
fi

# Install Java 17
log "Installing Java 17..."
if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
    sudo yum install java-17-openjdk java-17-openjdk-devel -y
else
    sudo apt install openjdk-17-jdk -y
fi

# Verify Java installation
java -version || error "Java installation failed"
log "Java 17 installed successfully"

# Install Git
log "Installing Git..."
if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
    sudo yum install git -y
else
    sudo apt install git -y
fi

git --version || error "Git installation failed"
log "Git installed successfully"

# Install Nginx
log "Installing Nginx..."
if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
    sudo yum install nginx -y
else
    sudo apt install nginx -y
fi

nginx -v || error "Nginx installation failed"
log "Nginx installed successfully"

# Install curl and other utilities
log "Installing utilities..."
if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
    sudo yum install curl wget htop nano -y
else
    sudo apt install curl wget htop nano -y
fi

# Install Docker (optional but recommended)
log "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh
log "Docker installed successfully (requires logout/login to use without sudo)"

# Create application directory
log "Creating application directories..."
sudo mkdir -p /opt/studio-finder
sudo chown $USER:$USER /opt/studio-finder
mkdir -p /opt/studio-finder/logs
mkdir -p /opt/studio-finder/backup

# Configure firewall
log "Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    # RHEL/CentOS/Oracle Linux
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --reload
    log "Firewall configured (firewall-cmd)"
elif command -v ufw &> /dev/null; then
    # Ubuntu/Debian
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 8080/tcp
    sudo ufw --force enable
    log "Firewall configured (ufw)"
else
    warn "No firewall detected. Please manually open ports 80, 443, and 8080"
fi

# Enable services
log "Enabling services..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Create deployment user (if not exists)
if ! id "deploy" &>/dev/null; then
    log "Creating deployment user..."
    sudo useradd -m -s /bin/bash deploy
    sudo usermod -aG docker deploy
    sudo mkdir -p /home/deploy/.ssh
    sudo chown deploy:deploy /home/deploy/.ssh
    sudo chmod 700 /home/deploy/.ssh
fi

# Set up log rotation
log "Setting up log rotation..."
sudo tee /etc/logrotate.d/studio-finder > /dev/null <<EOF
/opt/studio-finder/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 0644 $USER $USER
    postrotate
        systemctl reload studio-finder || true
    endscript
}
EOF

# Install Certbot for SSL (optional)
log "Installing Certbot for SSL certificates..."
if [[ "$PACKAGE_MANAGER" == "yum" ]]; then
    sudo yum install certbot python3-certbot-nginx -y
else
    sudo apt install certbot python3-certbot-nginx -y
fi

log "Server setup completed successfully!"
log "Next steps:"
log "1. Run the deployment script: ./deploy-app.sh"
log "2. Configure your Supabase credentials"
log "3. Test the deployment"

echo -e "${BLUE}"
echo "=============================================="
echo "    Studio Finder Server Setup Complete"
echo "=============================================="
echo -e "${NC}"
