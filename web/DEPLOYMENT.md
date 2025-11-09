# VibeTunnel Tailscale Deployment - Quick Start

Deploy VibeTunnel on your VPS with Tailscale for secure, authenticated terminal access from anywhere.

## 🚀 Quick Start (5 minutes)

### Prerequisites

1. **VPS with Linux** (Ubuntu, Debian, etc.)
2. **Tailscale installed and authenticated**
3. **Docker installed**

### One-Command Deployment

```bash
# On your VPS
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/vibetunnel/main/web/deploy-tailscale.sh | bash
```

Or manually:

```bash
# 1. Clone repo
git clone https://github.com/YOUR-USERNAME/vibetunnel.git
cd vibetunnel/web

# 2. Run deployment script
./deploy-tailscale.sh
```

The script will:
- ✅ Check prerequisites (Docker, Tailscale)
- ✅ Start VibeTunnel container
- ✅ Configure Tailscale Serve with HTTPS
- ✅ Set up authentication
- ✅ Display your access URL

### Access Your Terminal

After deployment, access VibeTunnel at:

```
https://your-machine.tail1234.ts.net
```

Only people on your tailnet can access it!

## 📁 Files Overview

### Production Files

- **`Dockerfile.production`** - Optimized production Docker image
- **`docker-compose.production.yml`** - Docker Compose for production deployment
- **`.env.production.example`** - Environment variables template
- **`deploy-tailscale.sh`** - Automated deployment script

### Development Files (Existing)

- **`Dockerfile`** - Development/testing image
- **`docker-compose.yml`** - Development environment

## 🔧 Manual Deployment

If you prefer manual control:

### 1. Install Prerequisites

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo apt install docker-compose-plugin
```

### 2. Deploy VibeTunnel

```bash
cd vibetunnel/web

# Option A: Build from source
docker compose -f docker-compose.production.yml up -d

# Option B: Use pre-built image (if available)
docker run -d \
  --name vibetunnel \
  -p 127.0.0.1:4020:4020 \
  -v vibetunnel-data:/home/vibetunnel/.vibetunnel \
  your-registry/vibetunnel:latest
```

### 3. Configure Tailscale Serve

```bash
# Enable HTTPS with authentication
sudo tailscale serve --bg --https=443 http://127.0.0.1:4020

# Check status
sudo tailscale serve status
```

### 4. Access Your Instance

Get your Tailscale hostname:

```bash
tailscale status --json | jq -r '.Self.DNSName'
# Output: my-vps.tail1234.ts.net
```

Access at: `https://my-vps.tail1234.ts.net`

## 🔐 Security

**Tailscale provides:**
- End-to-end encryption (WireGuard)
- Identity-based authentication
- Network isolation (only your tailnet)

**VibeTunnel adds:**
- User identification via Tailscale headers
- Session isolation
- Audit logging

### Authentication Options

```yaml
# In docker-compose.yml, choose one:

# Option 1: Tailscale identity auth (RECOMMENDED)
environment:
  # No special config needed - auto-detected

# Option 2: No authentication (tailnet only)
environment:
  - VIBETUNNEL_NO_AUTH=true

# Option 3: Password auth (legacy)
environment:
  - VIBETUNNEL_USERNAME=admin
  - VIBETUNNEL_PASSWORD=secure-password
```

## 📊 Monitoring

### View Logs

```bash
# Follow logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail=100

# Errors only
docker compose logs | grep -i error
```

### Check Status

```bash
# Container status
docker compose ps

# Health check
curl http://localhost:4020/api/health

# Tailscale status
sudo tailscale serve status
```

### Resource Usage

```bash
# Container stats
docker stats vibetunnel

# Disk usage
docker system df
```

## 🔄 Updates

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker compose -f docker-compose.production.yml build
docker compose -f docker-compose.production.yml up -d

# Or pull pre-built image
docker compose pull
docker compose up -d
```

## 🛠️ Troubleshooting

### Can't Access via Tailscale URL

```bash
# 1. Check VibeTunnel is running
curl http://localhost:4020/api/health

# 2. Check Tailscale Serve
sudo tailscale serve status

# 3. Restart Tailscale Serve
sudo tailscale serve reset
sudo tailscale serve --bg --https=443 http://127.0.0.1:4020
```

### Container Won't Start

```bash
# Check logs
docker compose logs

# Common fixes:
docker compose down
docker compose up -d

# Nuclear option:
docker compose down -v  # Removes volumes!
docker compose up -d
```

### Port Already in Use

```bash
# Find what's using port 4020
sudo lsof -i :4020

# Change port in docker-compose.yml:
ports:
  - "127.0.0.1:4021:4020"

# Then update Tailscale Serve:
sudo tailscale serve --bg --https=443 http://127.0.0.1:4021
```

## 📚 Documentation

- **Full deployment guide**: `docs/TAILSCALE_DEPLOYMENT.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **Configuration**: `.env.production.example`
- **Tailscale docs**: https://tailscale.com/kb

## 🎯 Use Cases

### Remote Development

Use Claude Code or AI coding assistants remotely:

```bash
# Access VibeTunnel from any device
# Create persistent terminal sessions
# Run long-running builds
# Access from phone/iPad
```

### Shared Team Access

Share terminal access with your team:

- Everyone on your tailnet gets access
- Tailscale ACLs control who can connect
- Each user authenticated by Tailscale identity
- Audit logs show who did what

### Mobile Terminal

Access your server from your phone:

1. Install Tailscale on iOS
2. Open Safari → `https://your-vps.tail1234.ts.net`
3. Add to Home Screen
4. Full terminal access from your phone!

## ⚙️ Advanced Configuration

### Custom Volumes

Mount your projects and configs:

```yaml
volumes:
  - vibetunnel-data:/home/vibetunnel/.vibetunnel
  - /home/user/projects:/workspace:rw
  - ~/.ssh:/home/vibetunnel/.ssh:ro
  - ~/.gitconfig:/home/vibetunnel/.gitconfig:ro
```

### Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      cpus: '1'
      memory: 1G
```

### Systemd Service

Auto-start on boot:

```bash
# Create service
sudo tee /etc/systemd/system/vibetunnel.service > /dev/null <<EOF
[Unit]
Description=VibeTunnel
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$HOME/vibetunnel/web
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

# Enable
sudo systemctl enable vibetunnel
sudo systemctl start vibetunnel
```

## 🤝 Support

- **Issues**: https://github.com/amantus-ai/vibetunnel/issues
- **Docs**: https://vibetunnel.sh
- **Tailscale**: https://tailscale.com/contact/support

---

**Happy tunneling!** 🚇
