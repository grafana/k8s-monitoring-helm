# Deployment Options for the Slack Bot

Here are your options for where and how to run the bot.

## Option 1: Local on Your Computer (Current Setup)

**What it means:**
- Bot runs on your laptop/desktop
- Reads from your local copy of the repo
- When your computer is off, the bot is offline

**When to use:**
- ✅ Testing and development
- ✅ Personal use
- ✅ You want to test changes to the repo before sharing

**Setup:**
```bash
cd slack-bot
python bot_no_api.py
```

**Pros:**
- Super easy to set up
- No server costs
- Easy to stop/start/test

**Cons:**
- Only online when your computer is on
- Requires your terminal to stay open
- Only you can restart it if it crashes

---

## Option 2: Server with Local Clone (Always On)

**What it means:**
- Bot runs on a server (cloud or office server)
- Clones the GitHub repo to the server
- Runs 24/7, accessible to your whole team

**When to use:**
- ✅ Production use for a team
- ✅ Want 24/7 availability
- ✅ Multiple people need to use it

**Setup on a Linux server:**
```bash
# SSH into your server
ssh your-server

# Clone the repo
git clone https://github.com/grafana/k8s-monitoring-helm.git
cd k8s-monitoring-helm/slack-bot

# Install dependencies
pip install -r requirements_no_api.txt

# Configure
cp env_no_api.example .env
nano .env  # Add your tokens

# Run in background
nohup python bot_no_api.py > bot.log 2>&1 &

# Or set up as a service (better for production)
sudo cp systemd/k8s-monitoring-bot.service /etc/systemd/system/
sudo systemctl enable k8s-monitoring-bot
sudo systemctl start k8s-monitoring-bot
```

**Pros:**
- ✅ Always online
- ✅ Whole team can use it
- ✅ Auto-restart on crash (with systemd)
- ✅ Not dependent on your laptop

**Cons:**
- Server costs (~$5-10/month)
- Need to manage a server

**Recommended servers:**
- DigitalOcean Droplet ($6/month)
- AWS EC2 t3.micro (~$8/month)
- Linode Shared ($5/month)
- Your company's existing server (free!)

---

## Option 3: Server with Remote Repo (No Local Clone Needed)

**What it means:**
- Bot runs on a server
- Automatically clones the repo from GitHub
- Can auto-update from GitHub periodically

**When to use:**
- ✅ Want to always use the latest docs from GitHub
- ✅ Don't want to manage a local clone
- ✅ Want the bot to auto-update

**Setup:**
```bash
# On your server
cd slack-bot

# Use the remote version
cp env_remote.example .env
nano .env  # Configure

# Run
python bot_no_api_remote.py
```

**In `.env`:**
```env
REMOTE_REPO_URL=https://github.com/grafana/k8s-monitoring-helm.git
REMOTE_REPO_BRANCH=main
LOCAL_CLONE_PATH=/tmp/k8s-monitoring-helm
AUTO_UPDATE_INTERVAL=3600  # Update every hour
```

**Pros:**
- ✅ Always uses latest docs from GitHub
- ✅ Auto-updates periodically
- ✅ No manual repo management

**Cons:**
- Requires internet access to GitHub
- Slight delay on first startup (cloning)

---

## Option 4: Docker (Easiest for Production)

**What it means:**
- Bot runs in a Docker container
- Container includes everything it needs
- Easy to deploy anywhere

**When to use:**
- ✅ You already use Docker
- ✅ Want easy deployment
- ✅ Want to run on Kubernetes

**Setup:**
```bash
cd slack-bot

# Build
docker build -f Dockerfile.no-api -t k8s-monitoring-bot .

# Run
docker run -d \
  --name k8s-monitoring-bot \
  --restart unless-stopped \
  --env-file .env \
  -v /path/to/k8s-monitoring-helm:/repo:ro \
  k8s-monitoring-bot

# Check logs
docker logs -f k8s-monitoring-bot

# Stop
docker stop k8s-monitoring-bot
```

**Or with Docker Compose:**
```bash
docker-compose up -d
```

**Pros:**
- ✅ Isolated environment
- ✅ Easy to deploy and update
- ✅ Auto-restarts
- ✅ Works anywhere Docker runs

**Cons:**
- Need Docker installed
- Slightly more complex setup

---

## Option 5: Kubernetes (Enterprise)

**What it means:**
- Bot runs as a Kubernetes deployment
- Highly available and scalable
- Auto-healing and monitoring

**When to use:**
- ✅ Large organization
- ✅ Already using Kubernetes
- ✅ Need high availability

**Setup:**
```yaml
# k8s-bot-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-monitoring-bot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: k8s-monitoring-bot
  template:
    metadata:
      labels:
        app: k8s-monitoring-bot
    spec:
      containers:
      - name: bot
        image: k8s-monitoring-bot:latest
        envFrom:
        - secretRef:
            name: slack-bot-secrets
        volumeMounts:
        - name: repo
          mountPath: /repo
          readOnly: true
      volumes:
      - name: repo
        gitRepo:
          repository: https://github.com/grafana/k8s-monitoring-helm.git
          revision: main
```

**Pros:**
- ✅ Enterprise-grade reliability
- ✅ Auto-scaling and healing
- ✅ Integrated monitoring

**Cons:**
- Requires Kubernetes cluster
- More complex setup

---

## Comparison Table

| Option | Cost | Setup Difficulty | Uptime | Best For |
|--------|------|------------------|--------|----------|
| **Local** | $0 | ⭐ Easy | When computer is on | Testing, personal use |
| **Server (clone)** | $5-10/mo | ⭐⭐ Medium | 24/7 | Small teams |
| **Server (remote)** | $5-10/mo | ⭐⭐ Medium | 24/7 | Teams, auto-update |
| **Docker** | $5-10/mo | ⭐⭐⭐ Medium+ | 24/7 | Production, easy deploy |
| **Kubernetes** | Varies | ⭐⭐⭐⭐ Hard | 99.9%+ | Enterprise |

---

## My Recommendation

### For Right Now (Testing):
**Option 1: Local on your computer**
- Get it working first
- Make sure it does what you want
- Test with your team

### For Production (After Testing):
**Option 2: Server with local clone**
- Deploy to a cheap server ($5/month)
- Set up systemd service
- Let your team use it 24/7

### If You Want Hands-Off:
**Option 4: Docker**
- Deploy with docker-compose
- Auto-restarts if it crashes
- Easy to update

---

## Quick Migration Path

1. **Week 1**: Run locally on your laptop (Option 1)
   - Test it out
   - Get team feedback
   
2. **Week 2**: If team likes it, deploy to server (Option 2)
   - Spin up a $5/month DigitalOcean droplet
   - Clone repo and run as systemd service
   - Now it's always available

3. **Later**: If you grow, move to Docker/K8s (Option 4/5)

---

## Example: Deploy to DigitalOcean ($6/month)

1. **Create a droplet**
   - Go to DigitalOcean
   - Create → Droplet
   - Choose Ubuntu 22.04
   - Pick $6/month plan
   - Click Create

2. **SSH in and set up**
   ```bash
   ssh root@your-droplet-ip
   
   # Install Python and Git
   apt update
   apt install -y python3 python3-pip git
   
   # Clone repo
   git clone https://github.com/grafana/k8s-monitoring-helm.git
   cd k8s-monitoring-helm/slack-bot
   
   # Install dependencies
   pip3 install -r requirements_no_api.txt
   
   # Configure
   cp env_no_api.example .env
   nano .env  # Add your Slack tokens
   
   # Run
   python3 bot_no_api.py
   ```

3. **Set up to run on boot**
   ```bash
   # Edit the systemd service file
   nano /etc/systemd/system/k8s-bot.service
   ```
   
   Add:
   ```ini
   [Unit]
   Description=K8s Monitoring Slack Bot
   After=network.target

   [Service]
   Type=simple
   User=root
   WorkingDirectory=/root/k8s-monitoring-helm/slack-bot
   ExecStart=/usr/bin/python3 bot_no_api.py
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```
   
   ```bash
   # Enable and start
   systemctl enable k8s-bot
   systemctl start k8s-bot
   
   # Check status
   systemctl status k8s-bot
   
   # View logs
   journalctl -u k8s-bot -f
   ```

Done! Your bot is now running 24/7 for $6/month! 🎉

---

## Summary

**Start local, move to server when ready!**

```
Your Laptop → Test (free, easy)
    ↓
Digital Ocean/AWS → Production (cheap, reliable)
    ↓
Docker/K8s → Scale (if needed)
```

Most teams are perfectly happy at the "server" level for months or years!
