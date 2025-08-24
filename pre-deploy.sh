#!/bin/bash
set -e

echo "🚀 Starting pre-deploy setup for Discourse..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log with colors
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right environment
if [ ! -d "/opt/bitnami/discourse" ]; then
    log_error "Not running in Bitnami Discourse environment"
    exit 1
fi

log_info "Running in Bitnami Discourse environment"

# Create necessary directories
log_info "Creating directories..."
mkdir -p /opt/bitnami/discourse/plugins
mkdir -p /opt/bitnami/discourse/mounted-conf

# Clone the discourse-oauth2-basic plugin
log_info "Cloning discourse-oauth2-basic plugin..."
cd /opt/bitnami/discourse/plugins

if [ -d "discourse-oauth2-basic" ]; then
    log_info "Plugin directory exists, pulling latest changes..."
    cd discourse-oauth2-basic
    git pull origin main
    cd ..
else
    log_info "Cloning plugin from GitHub..."
    git clone https://github.com/discourse/discourse-oauth2-basic.git
fi

# Verify plugin installation
log_info "Verifying plugin installation..."
if [ -d "discourse-oauth2-basic" ]; then
    log_success "Plugin directory created successfully"
    ls -la discourse-oauth2-basic/
else
    log_error "Plugin directory not found!"
    exit 1
fi

log_success "OAuth2 plugin installed successfully"

# Set up SSH key for private repo access (if needed)
if [ -n "$GITHUB_DEPLOY_KEY" ]; then
    log_info "Setting up GitHub deploy key..."
    mkdir -p ~/.ssh
    echo "$GITHUB_DEPLOY_KEY" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    
    # Add GitHub to known hosts
    echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> ~/.ssh/known_hosts
    
    log_success "GitHub deploy key configured"
fi

# Clone private config repo if specified
if [ -n "$CONFIG_REPO_URL" ]; then
    log_info "Cloning configuration repository..."
    cd /tmp
    
    if [ -d "discourse-config" ]; then
        log_info "Config directory exists, pulling latest changes..."
        cd discourse-config
        git pull origin main
    else
        log_info "Cloning config repository..."
        git clone "$CONFIG_REPO_URL" discourse-config
    fi
    
    # Copy configuration files
    if [ -f "discourse-config/discourse.conf" ]; then
        log_info "Copying discourse.conf..."
        cp discourse-config/discourse.conf /opt/bitnami/discourse/mounted-conf/
    fi
    
    if [ -f "discourse-config/site_settings.yml" ]; then
        log_info "Copying site_settings.yml..."
        cp discourse-config/site_settings.yml /opt/bitnami/discourse/mounted-conf/
    fi
    
    # Install additional plugins from plugins.txt
    if [ -f "discourse-config/plugins.txt" ]; then
        log_info "Installing plugins from plugins.txt..."
        cd /opt/bitnami/discourse/plugins
        
        while IFS= read -r plugin_url; do
            # Skip empty lines and comments
            [[ -z "$plugin_url" || "$plugin_url" =~ ^[[:space:]]*# ]] && continue
            
            plugin_name=$(basename "$plugin_url" .git)
            log_info "Installing plugin: $plugin_name"
            
            if [ -d "$plugin_name" ]; then
                log_info "Plugin $plugin_name exists, updating..."
                cd "$plugin_name"
                git pull origin main
                cd ..
            else
                log_info "Cloning plugin $plugin_name..."
                git clone "$plugin_url"
            fi
        done < /tmp/discourse-config/plugins.txt
        
        log_success "All plugins installed successfully"
    fi
    
    log_success "Configuration repository processed"
fi

# Set proper permissions
log_info "Setting permissions..."
chown -R 1001:1001 /opt/bitnami/discourse/plugins
chown -R 1001:1001 /opt/bitnami/discourse/mounted-conf

# Final verification
log_info "Final verification..."
echo "Plugin directory contents:"
ls -la /opt/bitnami/discourse/plugins/
echo ""
echo "OAuth2 plugin contents:"
ls -la /opt/bitnami/discourse/plugins/discourse-oauth2-basic/

log_success "Pre-deploy setup completed successfully!"
echo "📋 Summary:"
echo "   - OAuth2 plugin: /opt/bitnami/discourse/plugins/discourse-oauth2-basic"
echo "   - Config directory: /opt/bitnami/discourse/mounted-conf"
echo "   - Plugins directory: /opt/bitnami/discourse/plugins"
echo ""
echo "⚠️  IMPORTANT: Discourse may need to be restarted to recognize the new plugin!" 