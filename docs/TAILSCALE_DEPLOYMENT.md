# VibeTunnel Tailscale Deployment Guide

Deploy VibeTunnel on a VPS with Tailscale for secure, authenticated terminal access from anywhere on your tailnet.

## Overview

This guide sets up VibeTunnel with:
- ✅ **Secure Access**: Only people on your tailnet can connect
- ✅ **Auto-Authentication**: Users authenticated via Tailscale identity
- ✅ **HTTPS**: Automatic TLS via Tailscale Serve
- ✅ **Persistent Sessions**: Terminal sessions survive container restarts
- ✅ **Remote Access**: Use Claude Code or terminals from phone, iPad, anywhere

## Architecture

```
[Your Phone/Laptop] → [Tailscale Network] → [VPS Host]
                                                ↓
                                          [Tailscale Serve (HTTPS + Auth)]
                                                ↓
                                          [VibeTunnel Container (localhost:4020)]
                                                ↓
                                          [Terminal Sessions via PTY]
```

## Prerequisites

- VPS running Linux (Ubuntu 22.04+, Debian 11+, etc.)
- Docker and Docker Compose installed
- Tailscale account and tailnet set up

## Step 1: Install Tailscale on VPS

### Ubuntu/Debian

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale and authenticate
sudo tailscale up

# (Optional) Enable SSH over Tailscale
sudo tailscale up --ssh
```

### Other Linux Distributions

Follow the official installation guide at: https://tailscale.com/download/linux

### Verify Installation

```bash
# Check Tailscale status
tailscale status

# Get your machine's tailnet name
tailscale status --json | jq -r '.Self.DNSName'
# Example output: my-vps.tail1234.ts.net
```

## Step 2: Install Docker

### Ubuntu/Debian

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add your user to docker group (optional, allows non-root docker commands)
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Log out and back in for group changes to take effect
```

### Verify Installation

```bash
docker --version
docker compose version
```

## Step 3: Deploy VibeTunnel

### Clone Repository (or copy files)

```bash
# If deploying from your fork
git clone https://github.com/YOUR-USERNAME/vibetunnel.git
cd vibetunnel/web

# Or create a deployment directory
mkdir -p ~/vibetunnel-deploy
cd ~/vibetunnel-deploy
```

### Option A: Use Pre-built Docker Image (Recommended)

If you have a pre-built image on Docker Hub or GitHub Container Registry:

```bash
# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  vibetunnel:
    image: your-registry/vibetunnel:latest
    container_name: vibetunnel
    restart: unless-stopped

    ports:
      - "127.0.0.1:4020:4020"

    environment:
      - NODE_ENV=production
      - PORT=4020

    volumes:
      - vibetunnel-data:/home/vibetunnel/.vibetunnel

    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4020/api/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s

    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  vibetunnel-data:
EOF

# Start VibeTunnel
docker compose up -d

# Check logs
docker compose logs -f
```

### Option B: Build from Source

```bash
# Copy production files to your VPS
scp -r web/ your-vps:~/vibetunnel-deploy/

# SSH to your VPS
ssh your-vps
cd ~/vibetunnel-deploy/web

# Build and start
docker compose -f docker-compose.production.yml up -d

# Check logs
docker compose -f docker-compose.production.yml logs -f
```

### Verify VibeTunnel is Running

```bash
# Check container status
docker compose ps

# Test health endpoint
curl http://localhost:4020/api/health

# Should return: {"status":"ok",...}
```

## Step 4: Configure Tailscale Serve with Authentication

This is the critical step that provides HTTPS and authentication.

### Enable Tailscale Serve with Tailscale Auth

```bash
# Configure Tailscale Serve to proxy to VibeTunnel with authentication
sudo tailscale serve --set-path=/var/lib/tailscale/serve-config.json <<EOF
{
  "TCP": {
    "443": {
      "HTTPS": true
    }
  },
  "Web": {
    "${hostname}:443": {
      "/": {
        "Proxy": "http://127.0.0.1:4020"
      }
    }
  },
  "AllowFunnel": {}
}
EOF

# Or use the simpler command-line approach:
sudo tailscale serve --bg --https=443 --set-path="" http://127.0.0.1:4020
```

### Verify Tailscale Serve

```bash
# Check serve status
tailscale serve status

# Example output:
# https://my-vps.tail1234.ts.net (tailnet only)
# |-- / proxy http://127.0.0.1:4020
```

## Step 5: Configure Authentication

By default, Tailscale Serve provides authentication via identity headers. VibeTunnel reads these headers to identify users.

### Authentication Headers

Tailscale Serve automatically adds these headers:
- `Tailscale-User`: User's login name (e.g., `user@example.com`)
- `Tailscale-Login`: User's Tailscale login
- `Tailscale-Name`: User's display name
- `Tailscale-Profile-Picture`: User's avatar URL

### VibeTunnel Configuration Options

Edit your `docker-compose.yml` to configure authentication:

```yaml
environment:
  # Option 1: No authentication (rely on Tailscale network security)
  # - VIBETUNNEL_NO_AUTH=true

  # Option 2: Tailscale identity-based auth (RECOMMENDED)
  # No additional config needed - VibeTunnel auto-detects headers

  # Option 3: Password authentication (legacy)
  # - VIBETUNNEL_USERNAME=admin
  # - VIBETUNNEL_PASSWORD=your-secure-password
```

**Recommended**: Use Tailscale identity-based auth (no VIBETUNNEL_NO_AUTH). This ensures:
- Each user is identified by their Tailscale account
- You can see who's using the server in logs
- You can implement per-user access controls later

## Step 6: Access VibeTunnel from Your Devices

### From Browser

1. Open your tailnet machine URL:
   ```
   https://my-vps.tail1234.ts.net
   ```

2. You'll be automatically authenticated via Tailscale

3. Create terminal sessions and access them from any device on your tailnet

### From Mobile (iOS/iPad)

1. Install Tailscale on your iOS device
2. Connect to your tailnet
3. Open Safari or any browser
4. Navigate to `https://my-vps.tail1234.ts.net`
5. Add to Home Screen for native-like experience

### For Claude Code / AI Agents

VibeTunnel is perfect for running Claude Code or other AI coding assistants remotely:

```bash
# SSH to your VPS (via Tailscale SSH if enabled)
ssh my-vps

# Access the VibeTunnel terminal via browser
# Or use the VibeTunnel CLI locally to connect to remote sessions
```

## Configuration Options

### Environment Variables

Add to `docker-compose.yml` under `environment:`:

```yaml
# Debugging
- VIBETUNNEL_DEBUG=true          # Enable verbose logging

# Control directory
- VIBETUNNEL_CONTROL_DIR=/data/control  # Custom session data path

# Push notifications
- PUSH_CONTACT_EMAIL=you@example.com    # For web push notifications

# Verbosity (NEW)
- VIBETUNNEL_VERBOSITY=info     # none|error|warn|info|debug

# Git integration
- GIT_COMMITTER_NAME=VibeTunnel
- GIT_COMMITTER_EMAIL=bot@vibetunnel.local
```

### Volume Mounts

Mount additional directories for workspace access:

```yaml
volumes:
  - vibetunnel-data:/home/vibetunnel/.vibetunnel
  - /home/myuser/projects:/workspace:rw      # Mount your projects
  - ~/.ssh:/home/vibetunnel/.ssh:ro          # SSH keys for git
  - ~/.gitconfig:/home/vibetunnel/.gitconfig:ro  # Git config
```

### Resource Limits

Adjust based on your VPS specs:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'          # Max CPU cores
      memory: 4G         # Max RAM
    reservations:
      cpus: '1'          # Guaranteed CPU
      memory: 1G         # Guaranteed RAM
```

## Maintenance

### View Logs

```bash
# Follow logs
docker compose logs -f

# View last 100 lines
docker compose logs --tail=100

# View specific service logs
docker compose logs vibetunnel
```

### Update VibeTunnel

```bash
# Pull latest image
docker compose pull

# Restart with new image
docker compose up -d

# Or rebuild from source
docker compose -f docker-compose.production.yml build --no-cache
docker compose -f docker-compose.production.yml up -d
```

### Backup Data

```bash
# Backup session data
docker run --rm \
  -v vibetunnel-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/vibetunnel-backup-$(date +%Y%m%d).tar.gz /data

# Restore from backup
docker run --rm \
  -v vibetunnel-data:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/vibetunnel-backup-YYYYMMDD.tar.gz -C /
```

### Restart Services

```bash
# Restart VibeTunnel
docker compose restart

# Restart Tailscale Serve
sudo systemctl restart tailscaled

# Verify everything is running
tailscale serve status
docker compose ps
```

## Security Best Practices

### 1. **Use Tailscale ACLs**

Restrict who can access your VibeTunnel instance:

```json
// In Tailscale Admin Console → Access Controls
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:developers"],
      "dst": ["tag:vibetunnel:443"]
    }
  ],
  "tagOwners": {
    "tag:vibetunnel": ["you@example.com"]
  }
}
```

### 2. **Regular Updates**

```bash
# Update VibeTunnel
docker compose pull && docker compose up -d

# Update Tailscale
sudo apt update && sudo apt upgrade tailscale

# Update Docker
sudo apt update && sudo apt upgrade docker-ce docker-ce-cli
```

### 3. **Monitor Logs**

```bash
# Set up log monitoring (optional)
docker compose logs -f | grep -i error

# Or use systemd journal
journalctl -u docker -f | grep vibetunnel
```

### 4. **Firewall Configuration**

Since you're using Tailscale, you can restrict public access:

```bash
# Block all public access to port 4020
sudo ufw deny 4020

# Allow only Tailscale traffic (recommended)
sudo ufw allow in on tailscale0

# Enable firewall
sudo ufw enable
```

### 5. **Resource Limits**

Monitor resource usage:

```bash
# Check container stats
docker stats vibetunnel

# Set appropriate limits in docker-compose.yml (see Configuration section)
```

## Troubleshooting

### VibeTunnel Container Won't Start

```bash
# Check logs
docker compose logs

# Common issues:
# - Port 4020 already in use: Change PORT environment variable
# - Permission issues: Check volume permissions
# - Build errors: Run docker compose build --no-cache
```

### Can't Access via Tailscale URL

```bash
# Check Tailscale status
tailscale status

# Check serve configuration
tailscale serve status

# Verify VibeTunnel is responding
curl http://localhost:4020/api/health

# Check firewall
sudo ufw status

# Restart Tailscale Serve
sudo tailscale serve reset
sudo tailscale serve --bg --https=443 http://127.0.0.1:4020
```

### Authentication Not Working

```bash
# Check if Tailscale is sending identity headers
curl -H "Tailscale-User: test@example.com" http://localhost:4020/api/health

# Verify VibeTunnel auth configuration
docker compose exec vibetunnel env | grep AUTH

# Check logs for auth errors
docker compose logs | grep -i auth
```

### Terminal Sessions Not Persisting

```bash
# Check volume mount
docker volume inspect vibetunnel-data

# Verify data is being written
docker compose exec vibetunnel ls -la /home/vibetunnel/.vibetunnel/control

# Check permissions
docker compose exec vibetunnel stat /home/vibetunnel/.vibetunnel
```

### High Memory/CPU Usage

```bash
# Check stats
docker stats vibetunnel

# Reduce resource limits if needed
# Edit docker-compose.yml and restart

# Check for runaway processes
docker compose exec vibetunnel ps aux
```

## Advanced: Systemd Service

For automatic startup on boot:

```bash
# Create systemd service
sudo tee /etc/systemd/system/vibetunnel.service > /dev/null <<EOF
[Unit]
Description=VibeTunnel Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$HOME/vibetunnel-deploy/web
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
User=$USER

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable vibetunnel
sudo systemctl start vibetunnel

# Check status
sudo systemctl status vibetunnel
```

## Alternative: All-in-One Container with Tailscale

If you prefer running Tailscale inside the container (more complex but fully containerized):

See `docs/TAILSCALE_CONTAINER.md` for instructions on running Tailscale as a sidecar container.

## Support

- **Issues**: https://github.com/amantus-ai/vibetunnel/issues
- **Docs**: https://vibetunnel.sh
- **Tailscale Docs**: https://tailscale.com/kb

## Next Steps

- Explore the VibeTunnel web interface
- Set up git integration for automated workflows
- Configure push notifications for command completion
- Integrate with your CI/CD pipelines
- Use with Claude Code for AI-assisted development from anywhere
