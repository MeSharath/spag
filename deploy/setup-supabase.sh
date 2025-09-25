#!/bin/bash

# =============================================================================
# Studio Finder - Supabase Configuration Setup
# =============================================================================
# This script securely configures your Supabase connection
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_DIR="/opt/studio-finder"
ENV_FILE="$APP_DIR/backend/.env"

# Logging
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

# Prompt for Supabase credentials
prompt_credentials() {
    log "Please provide your Supabase credentials:"
    
    echo -n "Supabase Password: "
    read -s SUPABASE_PASSWORD
    echo
    
    if [ -z "$SUPABASE_PASSWORD" ]; then
        error "Supabase password is required!"
    fi
    
    log "Credentials received securely"
}

# Create secure environment file
create_env_file() {
    log "Creating secure environment configuration..."
    
    # Create backend directory if it doesn't exist
    mkdir -p "$APP_DIR/backend"
    
    # Create .env file with provided credentials
    cat > "$ENV_FILE" << EOF
# =============================================================================
# Studio Finder Backend - Environment Variables
# =============================================================================
# SECURITY: This file contains sensitive information
# NEVER commit this file to version control
# =============================================================================

# Spring Boot Configuration
SPRING_PROFILES_ACTIVE=prod

# Database Configuration (Supabase) - Will be prompted during setup
DATABASE_URL=jdbc:postgresql://db.schsrcjdukkduduueytz.supabase.co:5432/postgres
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=$SUPABASE_PASSWORD

# Server Configuration
SERVER_PORT=8080

# JVM Options for Production
JAVA_OPTS=-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseStringDeduplication

# Logging Configuration
LOGGING_LEVEL_ROOT=INFO
LOGGING_LEVEL_COM_SPAG_STUDIO=INFO
EOF
    
    # Set secure permissions (readable only by owner)
    chmod 600 "$ENV_FILE"
    
    log "✅ Environment file created: $ENV_FILE"
    log "✅ Secure permissions set (600)"
}

# Test database connection
test_connection() {
    log "Testing Supabase database connection..."
    
    # Install PostgreSQL client if not available
    if ! command -v psql &> /dev/null; then
        log "Installing PostgreSQL client..."
        if command -v yum &> /dev/null; then
            sudo yum install -y postgresql
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y postgresql-client
        else
            warn "Could not install PostgreSQL client. Skipping connection test."
            return
        fi
    fi
    
    # Test connection
    export PGPASSWORD="$SUPABASE_PASSWORD"
    
    if psql -h "db.schsrcjdukkduduueytz.supabase.co" -p 5432 -U postgres -d postgres \
        -c "SELECT version();" > /dev/null 2>&1; then
        log "✅ Database connection successful"
        
        # Check if studios table exists
        if psql -h "db.schsrcjdukkduduueytz.supabase.co" -p 5432 -U postgres -d postgres \
            -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'studios';" | grep -q "1"; then
            log "✅ Studios table exists"
        else
            warn "⚠️  Studios table not found. It will be created automatically when the app starts."
        fi
    else
        error "❌ Database connection failed. Please check your credentials."
    fi
    
    unset PGPASSWORD
}

# Create database schema
create_schema() {
    log "Creating database schema..."
    
    export PGPASSWORD="$SUPABASE_PASSWORD"
    
    # Create studios table
    psql -h "db.schsrcjdukkduduueytz.supabase.co" -p 5432 -U postgres -d postgres << 'EOF'
-- Create studios table if it doesn't exist
CREATE TABLE IF NOT EXISTS studios (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    image_url VARCHAR(500),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_studios_location ON studios(location);
CREATE INDEX IF NOT EXISTS idx_studios_price ON studios(price_per_hour);
CREATE INDEX IF NOT EXISTS idx_studios_available ON studios(is_available);
CREATE INDEX IF NOT EXISTS idx_studios_name ON studios(name);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_studios_updated_at ON studios;
CREATE TRIGGER update_studios_updated_at
    BEFORE UPDATE ON studios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data if table is empty
INSERT INTO studios (name, description, location, price_per_hour, image_url, contact_email, contact_phone)
SELECT * FROM (VALUES 
    ('Creative Sound Studio', 'Professional recording studio with state-of-the-art equipment. Perfect for music production, podcasts, and voice-overs.', 'Mumbai, Maharashtra', 2500.00, 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=500', 'info@creativesound.com', '+91-9876543210'),
    ('Harmony Music Hub', 'Spacious studio with excellent acoustics and professional mixing capabilities. Ideal for bands and solo artists.', 'Bangalore, Karnataka', 3000.00, 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500', 'contact@harmonymusic.com', '+91-9876543211'),
    ('Digital Dreams Studio', 'Modern digital recording facility with the latest software and hardware. Specializing in electronic music production.', 'Delhi, NCR', 2200.00, 'https://images.unsplash.com/photo-1571330735066-03aaa9429d89?w=500', 'hello@digitaldreams.com', '+91-9876543212'),
    ('Acoustic Vibes Studio', 'Intimate studio perfect for acoustic recordings and singer-songwriter sessions. Warm and cozy atmosphere.', 'Chennai, Tamil Nadu', 1800.00, 'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=500', 'info@acousticvibes.com', '+91-9876543213'),
    ('Pro Audio Labs', 'High-end professional studio with Grammy-winning engineers. Full production services available.', 'Pune, Maharashtra', 4500.00, 'https://images.unsplash.com/photo-1598653222000-6b7b7a552625?w=500', 'bookings@proaudiolabs.com', '+91-9876543214')
) AS sample_data(name, description, location, price_per_hour, image_url, contact_email, contact_phone)
WHERE NOT EXISTS (SELECT 1 FROM studios LIMIT 1);
EOF
    
    unset PGPASSWORD
    
    log "✅ Database schema created successfully"
}

# Update Flutter configuration
update_flutter_config() {
    log "Updating Flutter API configuration..."
    
    # Check if frontend directory exists
    if [ -d "$APP_DIR/../frontend" ]; then
        local api_service_file="$APP_DIR/../frontend/lib/services/api_service.dart"
        
        if [ -f "$api_service_file" ]; then
            # Update API base URL to use your server
            sed -i "s|static const String baseUrl = .*|static const String baseUrl = 'http://localhost:8080/api';|" "$api_service_file"
            log "✅ Flutter API configuration updated"
        else
            warn "Flutter API service file not found"
        fi
    else
        warn "Frontend directory not found. Update Flutter API URL manually."
    fi
}

# Show configuration summary
show_summary() {
    log "Supabase Configuration Summary:"
    
    echo -e "${BLUE}Database Details:${NC}"
    echo "  Host: db.schsrcjdukkduduueytz.supabase.co"
    echo "  Port: 5432"
    echo "  Database: postgres"
    echo "  Username: postgres"
    echo "  Password: ***hidden***"
    
    echo ""
    echo -e "${BLUE}Project Details:${NC}"
    echo "  Project URL: https://schsrcjdukkduduueytz.supabase.co"
    echo "  Project Reference: schsrcjdukkduduueytz"
    
    echo ""
    echo -e "${BLUE}Security:${NC}"
    echo "  ✅ Environment file secured (600 permissions)"
    echo "  ✅ Credentials not exposed in version control"
    echo "  ✅ Using production-ready configuration"
    
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Run: ./deploy-app.sh (will use these credentials automatically)"
    echo "  2. Update Flutter app API URL if needed"
    echo "  3. Test the deployment with: curl http://your-server/api/health"
}

# Main execution
main() {
    log "Setting up Supabase configuration for Studio Finder..."
    
    prompt_credentials
    create_env_file
    test_connection
    create_schema
    update_flutter_config
    show_summary
    
    log "✅ Supabase setup completed successfully!"
}

# Run main function
main "$@"
