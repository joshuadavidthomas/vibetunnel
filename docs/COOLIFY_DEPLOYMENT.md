# VibeTunnel Deployment on Coolify

Deploy VibeTunnel on Coolify with Tailscale for secure, authenticated terminal access from anywhere on your tailnet.

## Overview

This guide deploys VibeTunnel using Docker Compose on Coolify with:
- ✅ **Tailscale Integration**: Automatic tailnet connectivity
- ✅ **Secure Access**: Only accessible from your tailnet
- ✅ **HTTPS**: Via Tailscale (optional) or Coolify reverse proxy
- ✅ **Persistent Sessions**: Survives container restarts
- ✅ **Zero Configuration**: Works out of the box

## Architecture

```
[Your Phone/Laptop] → [Tailscale Network] → [Coolify Server]
                                                ↓
                                          [Tailscale Container]
                                                ↓
                                          [VibeTunnel Container]
                                                ↓
                                          [Terminal Sessions]
```

## Prerequisites

1. **Coolify instance** (self-hosted or cloud)
2. **Tailscale account** (free tier works)
3. **Git repository** with your VibeTunnel fork

## Step 1: Get Tailscale Auth Key

### Create Auth Key

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click **Generate auth key**
3. Configure the key:
   - ✅ **Reusable** (allows container restarts)
   - ✅ **Ephemeral** (optional - auto-cleanup when offline)
   - Set **Expiration** (90 days recommended, or never)
   - Optional: Add **Tags** for ACL control (e.g., `tag:vibetunnel`)

4. Copy the auth key (starts with `tskey-auth-`)
   ```
   tskey-auth-xxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxx
   ```

### Important Notes

- **Keep the auth key secret** - it grants access to your tailnet
- **Reusable keys** allow the container to restart without manual intervention
- **Tagged keys** enable ACL-based access control

## Step 2: Deploy to Coolify

### Option A: Deploy from Git Repository (Recommended)

1. **Create New Resource** in Coolify
   - Select **Docker Compose**
   - Choose **Git Repository**

2. **Configure Repository**
   - Repository URL: `https://github.com/YOUR-USERNAME/vibetunnel.git`
   - Branch: `main` (or your deployment branch)
   - Docker Compose Location: `web/docker-compose.coolify.yml`

3. **Set Environment Variables**

   Coolify automatically detects environment variables from the docker-compose file.

   In Coolify's **Environment** tab, you'll see all configurable variables. Set these:

   **REQUIRED:**
   - `TS_AUTHKEY`: Your Tailscale auth key (from previous step)

   **RECOMMENDED:**
   - `VIBETUNNEL_NO_AUTH`: Set to `true` (for tailnet-only access)
   - `VIBETUNNEL_VERBOSITY`: Set to `info` (or `debug` for troubleshooting)
   - `PUSH_CONTACT_EMAIL`: Your email address

   **OPTIONAL:**
   - `GIT_COMMITTER_NAME`: Name for git operations (default: VibeTunnel)
   - `GIT_COMMITTER_EMAIL`: Email for git operations (default: bot@vibetunnel.local)
   - `TS_HOSTNAME`: Custom hostname on tailnet (default: vibetunnel)

   All other variables have sensible defaults and can be left unchanged.

4. **Deploy**
   - Click **Deploy**
   - Wait for containers to start
   - Check logs for any errors

### Option B: Deploy from Docker Compose File

If you prefer to paste the compose file directly:

1. **Create New Resource** in Coolify
   - Select **Docker Compose**
   - Choose **Docker Compose (from file)**

2. **Paste Docker Compose**
   - Copy contents of `web/docker-compose.coolify.yml` from your repository
   - Paste into Coolify editor

3. **Configure Environment Variables**
   - Coolify will auto-detect all variables from the compose file
   - Go to **Environment** tab
   - Set `TS_AUTHKEY` (required) and any other variables you want to customize
   - See Configuration section below for all available options

4. **Deploy**

## Step 3: Verify Deployment

### Check Container Status

In Coolify:
1. Go to your VibeTunnel deployment
2. Check **Containers** tab
3. Verify both containers are running:
   - `vibetunnel-tailscale` (green)
   - `vibetunnel-app` (green)

### Check Tailscale Connection

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
2. Find your VibeTunnel machine (should show as online)
3. Note the Tailscale hostname (e.g., `vibetunnel.tail1234.ts.net`)

### Test Access

1. From a device on your tailnet, visit:
   ```
   http://vibetunnel.tail1234.ts.net:4020
   ```

2. You should see the VibeTunnel interface
3. Try creating a terminal session

## Step 4: Enable HTTPS (Optional)

You have two options for HTTPS:

### Option A: Coolify Reverse Proxy (Simpler)

1. In Coolify, go to your VibeTunnel deployment
2. Navigate to **Domains** tab
3. Add domain: `vibetunnel.your-domain.com`
4. Enable **SSL** (Coolify auto-provisions Let's Encrypt)
5. Configure proxy to forward to `vibetunnel:4020`

This gives you HTTPS via Coolify's reverse proxy.

### Option B: Tailscale HTTPS (No DNS needed)

Tailscale can provide HTTPS directly:

1. SSH into your Coolify server
2. Find the Tailscale container:
   ```bash
   docker ps | grep tailscale
   ```

3. Enable Tailscale HTTPS:
   ```bash
   docker exec vibetunnel-tailscale tailscale cert vibetunnel.tail1234.ts.net
   ```

4. Update docker-compose to use HTTPS (requires custom configuration)

**Recommendation**: Use Coolify reverse proxy for simplicity.

## Configuration

### Environment Variables

Coolify automatically detects all environment variables from the docker-compose file and provides a UI to configure them.

Navigate to your deployment → **Environment** tab to see and modify these values.

#### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `TS_AUTHKEY` | Tailscale auth key | `tskey-auth-xxxxx...` |

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
| `TS_HOSTNAME` | `vibetunnel` | Custom hostname on your tailnet |
| `TS_SSH` | `false` | Enable SSH access via Tailscale |

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

Edit in `docker-compose.coolify.yml`:

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
Edit `docker-compose.coolify.yml` and adjust:
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
