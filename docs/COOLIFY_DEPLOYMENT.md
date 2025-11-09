# VibeTunnel Deployment on Coolify with Tailscale

Deploy VibeTunnel on Coolify with Tailscale for secure, authenticated terminal access from anywhere on your tailnet.

## Overview

This guide deploys VibeTunnel using Docker Compose on Coolify with:
- ✅ **Tailscale Integration**: Coolify host on your tailnet
- ✅ **Secure Access**: Only accessible from your tailnet
- ✅ **No Auth Keys**: No expiring tokens to manage
- ✅ **Persistent Sessions**: Survives container restarts
- ✅ **Simple Configuration**: Just install Tailscale on host and deploy

## Architecture

```
[Your Phone/Laptop] → [Tailscale Network] → [Coolify VPS on Tailnet]
                                                ↓
                                          [VibeTunnel Container:4020]
```

**Key Point**: Tailscale runs on the Coolify host itself, not in containers. This eliminates auth key management.

## Prerequisites

1. **Coolify instance** (self-hosted or cloud)
2. **Tailscale account** (free tier works)
3. **SSH access to Coolify VPS**

## Step 1: Install Tailscale on Coolify VPS

SSH into your Coolify server and install Tailscale:

### Ubuntu/Debian

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale and join your tailnet
sudo tailscale up

# (Optional) Enable Tailscale SSH
sudo tailscale up --ssh

# Verify installation
tailscale status
```

### Get Your Tailnet Address

```bash
# Get your machine's tailnet hostname
tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//'

# Example output: coolify-vps.tail1234.ts.net
```

Save this hostname - you'll use it to access VibeTunnel!

## Step 2: Deploy VibeTunnel on Coolify

### Option A: Deploy from Git Repository (Recommended)

1. **Create New Resource** in Coolify
   - Select **Docker Compose**
   - Choose **Git Repository**

2. **Configure Repository**
   - Repository URL: `https://github.com/YOUR-USERNAME/vibetunnel.git`
   - Branch: `main` (or your deployment branch)
   - Docker Compose Location: `web/compose.yml`

3. **Configure Environment Variables (Optional)**

   Coolify automatically detects environment variables from the compose file.

   In Coolify's **Environment** tab, you'll see all configurable variables. Most have good defaults!

   **RECOMMENDED (already set by default):**
   - `VIBETUNNEL_NO_AUTH=true` (tailnet-only access, no passwords)
   - `VIBETUNNEL_VERBOSITY=info` (logging level)

   **OPTIONAL (customize if needed):**
   - `PUSH_CONTACT_EMAIL`: Your email for push notifications
   - `GIT_COMMITTER_NAME`: Name for git operations (default: VibeTunnel)
   - `GIT_COMMITTER_EMAIL`: Email for git operations (default: bot@vibetunnel.local)

   You can leave everything at defaults and it will work!

4. **Deploy**
   - Click **Deploy**
   - Wait for container to start
   - Check logs for any errors

### Option B: Deploy from Docker Compose File

If you prefer to paste the compose file directly:

1. **Create New Resource** in Coolify
   - Select **Docker Compose**
   - Choose **Docker Compose (from file)**

2. **Paste Docker Compose**
   - Copy contents of `web/compose.yml` from your repository
   - Paste into Coolify editor

3. **Configure Environment Variables (Optional)**
   - Coolify auto-detects all variables from the compose file
   - Go to **Environment** tab
   - Defaults are already set - you can deploy as-is!
   - See Configuration section below for customization options

4. **Deploy**

## Step 3: Verify Deployment

### Check Container Status

In Coolify:
1. Go to your VibeTunnel deployment
2. Check **Containers** tab
3. Verify container is running:
   - `vibetunnel` (green/healthy)

### Test Access from Your Tailnet

1. From any device on your tailnet (phone, laptop, etc.), visit:
   ```
   http://coolify-vps.tail1234.ts.net:4020
   ```
   (Replace with your actual Coolify VPS tailnet hostname)

2. You should see the VibeTunnel interface
3. Try creating a terminal session

**Note**: Only devices on your tailnet can access this. Public internet cannot reach it!

## Step 4: Enable HTTPS (Optional)

You have two options for HTTPS:

### Option A: Tailscale HTTPS (Easiest - No DNS needed!)

Tailscale can provide HTTPS for free:

```bash
# On your Coolify VPS
sudo tailscale cert $(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')
```

This creates SSL certificates that work with your tailnet hostname. Then update your VibeTunnel configuration to use HTTPS on port 443.

Access at: `https://coolify-vps.tail1234.ts.net`

**Pros**: Free, automatic, works on tailnet only
**Cons**: Requires additional configuration

### Option B: Tailscale Funnel (Public HTTPS)

If you want to make VibeTunnel accessible to the public internet:

```bash
# On your Coolify VPS
sudo tailscale funnel 4020
```

This creates a public HTTPS URL that anyone can access.

**Warning**: This makes your VibeTunnel publicly accessible! Consider enabling password authentication if using funnel.

### Option C: Coolify Reverse Proxy

1. In Coolify, go to your VibeTunnel deployment
2. Navigate to **Domains** tab
3. Add domain: `vibetunnel.your-domain.com`
4. Enable **SSL** (Coolify auto-provisions Let's Encrypt)

**Recommendation**: Use Tailscale HTTPS (Option A) for tailnet-only access with encryption.

## Configuration

### Environment Variables

Coolify automatically detects all environment variables from the docker-compose file and provides a UI to configure them.

Navigate to your deployment → **Environment** tab to see and modify these values.

#### Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `VIBETUNNEL_NO_AUTH` | `true` | Set to `true` for tailnet-only access (no passwords) |
| `VIBETUNNEL_USERNAME` | - | Username for password auth (only if `NO_AUTH=false`) |
| `VIBETUNNEL_PASSWORD` | - | Password for password auth (only if `NO_AUTH=false`) |

**Recommendation:** Keep `VIBETUNNEL_NO_AUTH=true` since Tailscale already provides security.

#### Logging

| Variable | Default | Description |
|----------|---------|-------------|
| `VIBETUNNEL_VERBOSITY` | `info` | Logging level: `none`, `error`, `warn`, `info`, `debug` |
| `VIBETUNNEL_DEBUG` | `false` | Enable debug mode for detailed logs |

#### Optional Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `PUSH_CONTACT_EMAIL` | `noreply@vibetunnel.local` | Email for push notification VAPID config |
| `GIT_COMMITTER_NAME` | `VibeTunnel` | Name for git operations in terminals |
| `GIT_COMMITTER_EMAIL` | `bot@vibetunnel.local` | Email for git operations |
| `PORT` | `4020` | Port to expose VibeTunnel on (change if needed) |

**Note:** Coolify shows all these variables in the UI with their default values. You only need to change the ones you want to customize.

### Volume Mounts

Add persistent volumes in Coolify:

```yaml
# In Coolify's Volumes tab:
/path/on/host/workspace → /workspace (in vibetunnel container)
/path/on/host/.ssh → /home/vibetunnel/.ssh (read-only)
/path/on/host/.gitconfig → /home/vibetunnel/.gitconfig (read-only)
```

### Resource Limits

Edit in `compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'      # Adjust based on server
      memory: 4G
    reservations:
      cpus: '1'
      memory: 1G
```

Then redeploy in Coolify.

## Access from Devices

### Desktop Browser

1. Ensure Tailscale is running on your computer
2. Visit: `http://vibetunnel.tail1234.ts.net:4020`
3. Create and use terminal sessions

### Mobile (iOS/Android)

1. Install Tailscale app on your phone
2. Connect to your tailnet
3. Open browser (Safari/Chrome)
4. Visit: `http://vibetunnel.tail1234.ts.net:4020`
5. **Pro tip**: Add to Home Screen for app-like experience

### iPad

Same as mobile - works great with external keyboard!

### From Claude Code

Access VibeTunnel from any AI coding assistant:

1. Create persistent terminal session in VibeTunnel
2. Run your AI coding tools (Claude Code, Cursor, etc.)
3. Access from any device on your tailnet
4. Sessions persist across disconnects

## Monitoring and Maintenance

### View Logs

In Coolify:
1. Go to your VibeTunnel deployment
2. Click **Logs** tab
3. Select container:
   - `vibetunnel-app` for application logs
   - `vibetunnel-tailscale` for network logs

### Update VibeTunnel

1. In Coolify, go to your deployment
2. Click **Redeploy** button
3. Coolify pulls latest changes and rebuilds

Or trigger via Git:
1. Push changes to your repository
2. Coolify auto-deploys (if auto-deploy enabled)

### Restart Containers

In Coolify:
1. Go to **Containers** tab
2. Click restart icon for specific container
3. Or click **Restart** at deployment level

### Check Health

VibeTunnel includes health checks:

```bash
# From Coolify server
docker exec vibetunnel-app curl -f http://localhost:4020/api/health
```

Or visit: `http://vibetunnel.tail1234.ts.net:4020/api/health`

## Security Best Practices

### 1. Use Tailscale ACLs

Control who can access VibeTunnel:

```json
// In Tailscale Admin Console → Access Controls
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:developers"],
      "dst": ["tag:vibetunnel:*"]
    }
  ],
  "tagOwners": {
    "tag:vibetunnel": ["you@example.com"]
  }
}
```

### 2. Rotate Auth Keys

Periodically rotate Tailscale auth keys:

1. Generate new auth key in Tailscale admin
2. Update `TS_AUTHKEY` in Coolify environment
3. Redeploy
4. Revoke old key

### 3. Monitor Access

Check Tailscale admin for:
- Active connections
- Authentication attempts
- Unusual access patterns

### 4. Regular Updates

Update VibeTunnel regularly:
- Security patches
- New features
- Bug fixes

### 5. Limit Exposed Ports

Don't expose VibeTunnel ports publicly:
- Keep ports internal to Docker network
- Access only via Tailscale
- Use Coolify's reverse proxy for HTTPS if needed

## Troubleshooting

### Containers Won't Start

**Check logs in Coolify:**
```
Error: TS_AUTHKEY is required
```
**Solution**: Add `TS_AUTHKEY` to environment variables

---

**Check logs:**
```
Error: Failed to connect to Tailscale
```
**Solution**:
- Verify auth key is valid
- Check if key is expired
- Ensure container has `NET_ADMIN` capability

### Can't Access via Tailscale

**Check Tailscale status:**

```bash
# On Coolify server
docker exec vibetunnel-tailscale tailscale status
```

**Verify machine is online:**
- Go to Tailscale admin console
- Check if machine shows as online
- Verify correct hostname

**Test connectivity:**
```bash
# From another machine on tailnet
ping vibetunnel.tail1234.ts.net
curl http://vibetunnel.tail1234.ts.net:4020/api/health
```

### Authentication Fails

**If using `VIBETUNNEL_NO_AUTH=true`:**
- Should auto-login, no password needed
- Check VibeTunnel logs for errors

**If using password auth:**
- Verify `VIBETUNNEL_USERNAME` and `VIBETUNNEL_PASSWORD` are set
- Check they match what you're entering

**Check logs:**
```bash
docker exec vibetunnel-app cat /home/vibetunnel/.vibetunnel/control/server.log
```

### Terminal Sessions Not Persisting

**Check volumes:**

In Coolify, verify `vibetunnel-data` volume exists:
```bash
docker volume ls | grep vibetunnel
```

**Check data directory:**
```bash
docker exec vibetunnel-app ls -la /home/vibetunnel/.vibetunnel/control/
```

**Fix permissions:**
```bash
docker exec vibetunnel-app chown -R vibetunnel:vibetunnel /home/vibetunnel/.vibetunnel
```

### High Resource Usage

**Check container stats:**
```bash
docker stats vibetunnel-app vibetunnel-tailscale
```

**Reduce limits:**
Edit `compose.yml` and adjust:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

Then redeploy in Coolify.

### Tailscale Container Exits

**Check logs:**
```bash
docker logs vibetunnel-tailscale
```

**Common issues:**
- Expired auth key → Generate new key
- Missing `NET_ADMIN` capability → Check Coolify privileges
- Invalid Tailscale configuration → Check environment variables

**Restart:**
```bash
docker restart vibetunnel-tailscale
```

## Advanced Configuration

### Custom Tailscale Serve Config

Enable HTTPS with automatic Tailscale authentication:

1. Create `tailscale-serve.json`:
   ```json
   {
     "TCP": {
       "443": {
         "HTTPS": true
       }
     },
     "Web": {
       "vibetunnel.tail1234.ts.net:443": {
         "/": {
           "Proxy": "http://vibetunnel:4020"
         }
       }
     }
   }
   ```

2. Mount in docker-compose:
   ```yaml
   tailscale:
     volumes:
       - ./tailscale-serve.json:/config/serve.json:ro
     environment:
       - TS_SERVE_CONFIG=/config/serve.json
   ```

3. Redeploy in Coolify

### Use Coolify Secrets

Store sensitive values as Coolify secrets:

1. In Coolify, go to **Environment**
2. Click **Add Secret**
3. Name: `TS_AUTHKEY`
4. Value: Your auth key
5. Mark as secret (hidden in UI)

Reference in compose:
```yaml
environment:
  - TS_AUTHKEY=${TS_AUTHKEY}
```

### Network Customization

Add to existing Docker network:

```yaml
networks:
  vibetunnel-network:
    external: true
    name: coolify-network
```

This allows VibeTunnel to communicate with other Coolify services.

### Multi-Instance Deployment

Run multiple VibeTunnel instances:

1. Copy compose file
2. Change service names (vibetunnel-dev, vibetunnel-prod)
3. Use different auth keys for each
4. Deploy as separate Coolify projects

## Backup and Restore

### Backup Session Data

```bash
# On Coolify server
docker run --rm \
  -v vibetunnel_vibetunnel-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/vibetunnel-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore from Backup

```bash
# Stop VibeTunnel in Coolify first

# Restore data
docker run --rm \
  -v vibetunnel_vibetunnel-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/vibetunnel-backup-YYYYMMDD.tar.gz -C /

# Restart in Coolify
```

## Migration to Different Server

1. **Export from old Coolify:**
   - Download compose file
   - Export environment variables
   - Backup volumes

2. **Import to new Coolify:**
   - Create new deployment
   - Paste compose file
   - Add environment variables
   - Restore volumes

3. **Update Tailscale:**
   - Old machine will show offline
   - New machine appears with same/different hostname
   - Update ACLs if needed

## FAQ

### Q: Do I need to open any ports?

**A:** No! Tailscale handles all networking. VibeTunnel is only accessible via your tailnet.

### Q: Can I use my own domain?

**A:** Yes! Use Coolify's reverse proxy:
1. Add domain in Coolify
2. Configure SSL
3. Proxy to `vibetunnel:4020`

### Q: How do I add more users?

**A:** Add them to your Tailscale network. They'll automatically get access (with `VIBETUNNEL_NO_AUTH=true`).

### Q: Can I restrict access to specific users?

**A:** Yes! Use Tailscale ACLs to control who can connect to the VibeTunnel machine.

### Q: Does it work on mobile?

**A:** Yes! Works great on iOS/Android with Tailscale app + browser. Add to Home Screen for best experience.

### Q: What about data persistence?

**A:** Session data persists in Docker volumes. Survives container restarts but not volume deletion.

### Q: How do I update VibeTunnel?

**A:** Click "Redeploy" in Coolify. It pulls latest code and rebuilds.

### Q: Can I run multiple instances?

**A:** Yes! Deploy multiple times with different service names and Tailscale auth keys.

## Support

- **VibeTunnel Issues**: https://github.com/amantus-ai/vibetunnel/issues
- **Coolify Docs**: https://coolify.io/docs
- **Tailscale Support**: https://tailscale.com/contact/support
- **This Fork**: https://github.com/YOUR-USERNAME/vibetunnel

## Next Steps

- Explore VibeTunnel features
- Set up git integration
- Configure push notifications
- Integrate with CI/CD
- Use with Claude Code for AI-assisted development

---

**Enjoy your secure, Tailscale-powered terminal access!** 🚀
