#!/bin/bash
# VibeTunnel Tailscale Deployment Script
# This script automates the deployment of VibeTunnel on a VPS with Tailscale

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        return 1
    fi
    log_success "$1 is installed"
    return 0
}

# Header
echo "=================================="
echo "VibeTunnel Tailscale Deployment"
echo "=================================="
echo ""

# Check prerequisites
log_info "Checking prerequisites..."

if ! check_command docker; then
    log_error "Install Docker: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

if ! check_command tailscale; then
    log_error "Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
    exit 1
fi

# Check if Tailscale is authenticated
if ! tailscale status &> /dev/null; then
    log_warning "Tailscale is not authenticated"
    log_info "Run: sudo tailscale up"
    exit 1
fi

log_success "All prerequisites met"
echo ""

# Get Tailscale hostname
TAILSCALE_HOST=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | cut -d'"' -f4 | sed 's/\.$//')
if [ -z "$TAILSCALE_HOST" ]; then
    log_error "Could not determine Tailscale hostname"
    exit 1
fi

log_info "Tailscale hostname: $TAILSCALE_HOST"
echo ""

# Choose deployment method
echo "Select deployment method:"
echo "  1) Build from source (requires source code)"
echo "  2) Use docker-compose.production.yml"
echo "  3) Quick setup with inline docker-compose.yml"
echo ""
read -p "Enter choice [1-3]: " DEPLOY_METHOD

case $DEPLOY_METHOD in
    1)
        log_info "Building from source..."
        if [ ! -f "Dockerfile.production" ]; then
            log_error "Dockerfile.production not found. Are you in the correct directory?"
            exit 1
        fi
        docker compose -f docker-compose.production.yml build
        docker compose -f docker-compose.production.yml up -d
        ;;
    2)
        log_info "Using docker-compose.production.yml..."
        if [ ! -f "docker-compose.production.yml" ]; then
            log_error "docker-compose.production.yml not found"
            exit 1
        fi
        docker compose -f docker-compose.production.yml up -d
        ;;
    3)
        log_info "Setting up quick deployment..."

        # Create minimal docker-compose.yml
        cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  vibetunnel:
    image: node:22-slim
    container_name: vibetunnel
    restart: unless-stopped
    command: >
      sh -c "
        apt-get update && apt-get install -y curl git libpam0g &&
        npm install -g pnpm vibetunnel &&
        vibetunnel --bind 0.0.0.0 --port 4020
      "
    ports:
      - "127.0.0.1:4020:4020"
    volumes:
      - vibetunnel-data:/root/.vibetunnel
    environment:
      - NODE_ENV=production
      - PORT=4020

volumes:
  vibetunnel-data:
EOF

        docker compose up -d
        ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

log_success "VibeTunnel container started"
echo ""

# Wait for container to be healthy
log_info "Waiting for VibeTunnel to start..."
sleep 5

# Check if VibeTunnel is responding
if curl -f http://localhost:4020/api/health &> /dev/null; then
    log_success "VibeTunnel is responding on localhost:4020"
else
    log_error "VibeTunnel is not responding. Check logs with: docker compose logs"
    exit 1
fi

echo ""

# Configure Tailscale Serve
log_info "Configuring Tailscale Serve..."

# Reset any existing serve configuration
sudo tailscale serve reset 2>/dev/null || true

# Set up Tailscale Serve with HTTPS
if sudo tailscale serve --bg --https=443 http://127.0.0.1:4020; then
    log_success "Tailscale Serve configured"
else
    log_error "Failed to configure Tailscale Serve"
    log_info "Try manually: sudo tailscale serve --bg --https=443 http://127.0.0.1:4020"
    exit 1
fi

echo ""

# Show status
log_info "Checking Tailscale Serve status..."
sudo tailscale serve status

echo ""
echo "=================================="
log_success "Deployment Complete!"
echo "=================================="
echo ""
echo "Access VibeTunnel at:"
echo "  https://$TAILSCALE_HOST"
echo ""
echo "Useful commands:"
echo "  View logs:     docker compose logs -f"
echo "  Restart:       docker compose restart"
echo "  Stop:          docker compose down"
echo "  Serve status:  sudo tailscale serve status"
echo ""
echo "Documentation:"
echo "  See docs/TAILSCALE_DEPLOYMENT.md for detailed information"
echo ""
