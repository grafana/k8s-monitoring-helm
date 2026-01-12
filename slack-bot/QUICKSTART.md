# Quick Start Guide

Get your K8s Monitoring Helm Slack Bot up and running in 5 minutes!

## Prerequisites

- Python 3.9+
- Slack workspace admin access
- OpenAI API key

## Step 1: Run Setup Script

```bash
cd slack-bot
./setup.sh
```

This will:
- Create a Python virtual environment
- Install all dependencies
- Create a `.env` file from the template

## Step 2: Create Slack App

1. Go to https://api.slack.com/apps → "Create New App" → "From scratch"
2. Name it "K8s Monitoring Bot" and select your workspace
3. Configure the app:

### OAuth & Permissions
Add these Bot Token Scopes:
- `app_mentions:read`
- `chat:write`
- `channels:history`
- `channels:read`

### Socket Mode
- Enable Socket Mode
- Generate an App-Level Token with `connections:write` scope

### Event Subscriptions
- Enable Events
- Subscribe to bot events:
  - `app_mention`
  - `message.channels`

### Slash Commands (Optional)
- Create command: `/k8s-help`
- Request URL: (not needed with Socket Mode)

### Install App
- Click "Install to Workspace"
- Authorize the app

## Step 3: Get API Keys

### Slack Tokens
- **Bot Token**: OAuth & Permissions page (starts with `xoxb-`)
- **App Token**: Socket Mode page (starts with `xapp-`)
- **Signing Secret**: Basic Information page

### OpenAI Key
- Go to https://platform.openai.com/api-keys
- Create new key (starts with `sk-`)

## Step 4: Configure Environment

Edit `.env` file:

```bash
nano .env
```

Add your credentials:
```env
SLACK_BOT_TOKEN=xoxb-your-actual-token
SLACK_APP_TOKEN=xapp-your-actual-token
SLACK_SIGNING_SECRET=your-actual-secret
OPENAI_API_KEY=sk-your-actual-key
```

## Step 5: Start the Bot

```bash
source venv/bin/activate
python bot.py
```

First run will index the repository (takes 2-3 minutes).

## Step 6: Test It!

In Slack:
1. Invite the bot to a channel: `/invite @k8s-monitoring-bot`
2. Ask a question: `@k8s-monitoring-bot how do I configure OTLP destinations?`
3. Or just ask: `How do I enable pod logs?`

## Common Issues

### Bot doesn't respond
- Invite bot to channel: `/invite @k8s-monitoring-bot`
- Check bot is running: Look for "k8s-monitoring-bot is running!" in logs
- Verify Socket Mode is enabled

### "Import Error"
```bash
# Make sure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### "OpenAI API Error"
- Check your API key is valid
- Verify you have API credits: https://platform.openai.com/usage
- Try `gpt-4o-mini` in .env if rate limited

### Slow responses
- First response is slow (indexing)
- Subsequent responses: 3-5 seconds
- Use `gpt-4o-mini` for faster responses

## Usage Examples

```
# Configuration questions
@bot How do I configure multiple destinations?
@bot Show me an example values.yaml

# Feature questions  
@bot How do I enable cluster metrics?
@bot What collectors are available?

# Troubleshooting
@bot Why aren't my logs showing up?
@bot How do I debug alloy?

# Auto-detection (no mention needed)
How do I set up Prometheus authentication?
Can I send traces to multiple destinations?
```

## Next Steps

- Read the full [README.md](README.md)
- Check [example questions](README.md#example-questions)
- Learn about [deployment options](README.md#deployment)
- See [configuration options](README.md#configuration)

## Support

Questions? The bot can help with that! 😉

Or check:
- Bot logs for errors
- Slack app event subscriptions
- OpenAI API status
