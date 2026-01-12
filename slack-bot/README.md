# K8s Monitoring Helm Slack Bot

A Slack bot that answers questions about the k8s-monitoring-helm repository using AI-powered semantic search and OpenAI's GPT models.

## 🎯 Two Versions Available

| Version | Description | Best For | Cost |
|---------|-------------|----------|------|
| **Full** (`bot.py`) | AI-powered explanations using GPT-4 | Natural language answers, complex questions | ~$5-20/month |
| **No-API** (`bot_no_api.py`) | Local search, returns docs directly | Quick lookups, zero budget | **$0/month** |

👉 **New to this?** Start with the **No-API version** - it's free and works great for most use cases!

📊 **Need to decide?** Check out the [detailed comparison](COMPARISON.md)

## Features

- 🤖 Answers questions about the k8s-monitoring-helm chart configuration
- 🔍 Semantic search across the repository
- 📚 Context-aware responses using documentation and examples
- 💬 Responds to mentions and detects relevant questions automatically
- 🔐 Secure authentication with Slack and OpenAI

## Prerequisites

### For Full Version
- Python 3.9 or higher
- Slack workspace with admin access
- OpenAI API key (costs apply)
- Repository cloned locally

### For No-API Version
- Python 3.9 or higher
- Slack workspace with admin access
- Repository cloned locally

**No OpenAI API key needed!** ✨

## Setup

### 1. Install Dependencies

```bash
cd slack-bot
pip install -r requirements.txt
```

### 2. Create a Slack App

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Click "Create New App" → "From scratch"
3. Name it (e.g., "K8s Monitoring Bot") and select your workspace
4. Go to "OAuth & Permissions" and add these **Bot Token Scopes**:
   - `app_mentions:read` - View messages that directly mention your bot
   - `chat:write` - Send messages as the bot
   - `channels:history` - View messages in channels
   - `groups:history` - View messages in private channels
   - `im:history` - View messages in direct messages
   - `mpim:history` - View messages in group direct messages
   - `channels:read` - View basic information about channels
   - `groups:read` - View basic information about private channels

5. Install the app to your workspace (you'll get the Bot Token)
6. Go to "Socket Mode" and enable it (you'll get the App Token)
7. Go to "Event Subscriptions":
   - Enable Events
   - Subscribe to bot events: `app_mention`, `message.channels`, `message.groups`, `message.im`, `message.mpim`
8. Go to "Slash Commands" and create `/k8s-help` command
9. Go to "Basic Information" and get the Signing Secret

### 3. Get OpenAI API Key

1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Create a new API key
3. Save it securely

### 4. Configure Environment Variables

```bash
# Copy the example env file
cp .env.example .env

# Edit .env with your credentials
nano .env
```

Fill in the following:
```env
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_APP_TOKEN=xapp-your-app-token
SLACK_SIGNING_SECRET=your-signing-secret
OPENAI_API_KEY=sk-your-openai-key
REPO_PATH=/path/to/k8s-monitoring-helm
```

### 5. Index the Repository

The bot will automatically index the repository on first run. This takes a few minutes but only needs to be done once (or when the repo changes significantly).

```bash
python bot.py
```

## Usage

### Asking Questions

The bot responds to questions in several ways:

1. **Direct mention**: `@k8s-monitoring-bot how do I configure multiple OTLP destinations?`

2. **Automatic detection**: Ask a question with a `?` that contains relevant keywords:
   ```
   How do I enable pod logs collection?
   Can I send traces to Tempo?
   What's the syntax for prometheus destinations?
   ```

3. **Help command**: `/k8s-help` to see usage instructions

### Example Questions

- "How do I configure multiple OTLP destinations?"
- "What's the difference between alloy-metrics and alloy-logs?"
- "How do I enable cluster events collection?"
- "Can the URL field take multiple values in OTLP destinations?"
- "How do I set up authentication for Prometheus?"
- "Show me an example of a Loki destination configuration"
- "How do I enable traces only for a specific namespace?"

## Architecture

```
┌─────────────┐
│   Slack     │
│  Channel    │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│   Slack Bot (bot.py)│
│                     │
│  - Event Handler    │
│  - Message Router   │
└──────┬──────────────┘
       │
       ├─────────────────┐
       ▼                 ▼
┌──────────────┐  ┌─────────────────┐
│ RepoIndexer  │  │ ContextBuilder  │
│              │  │                 │
│ - ChromaDB   │  │ - Keyword Match │
│ - Embeddings │  │ - Semantic Search│
└──────────────┘  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  OpenAI GPT-4   │
                  │                 │
                  │ - Context-aware │
                  │ - Code examples │
                  └─────────────────┘
```

## Components

### bot.py
Main bot application that:
- Handles Slack events and messages
- Routes questions to the appropriate handlers
- Manages conversation threading
- Formats responses for Slack

### repo_indexer.py
Repository indexing system that:
- Indexes markdown, YAML, and code files
- Creates vector embeddings using sentence-transformers
- Stores embeddings in ChromaDB
- Provides semantic search functionality

### context_builder.py
Context building system that:
- Extracts keywords from questions
- Searches for relevant documentation
- Finds matching examples
- Builds comprehensive context for AI responses

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SLACK_BOT_TOKEN` | Slack bot token (required) | - |
| `SLACK_APP_TOKEN` | Slack app token for Socket Mode (required) | - |
| `SLACK_SIGNING_SECRET` | Slack signing secret (required) | - |
| `OPENAI_API_KEY` | OpenAI API key (required) | - |
| `OPENAI_MODEL` | OpenAI model to use | `gpt-4o` |
| `REPO_PATH` | Path to k8s-monitoring-helm repo | Parent dir |
| `BOT_NAME` | Name of the bot | `k8s-monitoring-bot` |
| `ENABLE_VECTOR_SEARCH` | Enable semantic search | `true` |
| `MAX_CONTEXT_FILES` | Max files to include in context | `5` |
| `MAX_RESPONSE_LENGTH` | Max response length in chars | `3000` |
| `MONITORED_CHANNELS` | Specific channels to monitor (comma-separated) | All channels |

### Updating the Index

If the repository changes significantly, re-index by deleting the index directory:

```bash
rm -rf .slack-bot-index
python bot.py
```

## Development

### Running in Development

```bash
# Enable debug logging
export LOG_LEVEL=DEBUG

# Run the bot
python bot.py
```

### Testing

Test the context builder:
```bash
python -c "
from context_builder import ContextBuilder
from repo_indexer import RepoIndexer

indexer = RepoIndexer('.')
builder = ContextBuilder('.', indexer)
context = builder.build_context('How do I configure OTLP destinations?')
print(context)
"
```

### Adding New Features

1. Add new keyword mappings in `context_builder.py`
2. Enhance the system prompt in `bot.py`
3. Add custom handlers for specific question types

## Deployment

### Running as a Service (systemd)

Create `/etc/systemd/system/k8s-monitoring-bot.service`:

```ini
[Unit]
Description=K8s Monitoring Helm Slack Bot
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/path/to/k8s-monitoring-helm/slack-bot
Environment="PATH=/path/to/venv/bin"
ExecStart=/path/to/venv/bin/python bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable k8s-monitoring-bot
sudo systemctl start k8s-monitoring-bot
sudo systemctl status k8s-monitoring-bot
```

### Running with Docker

Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "bot.py"]
```

Build and run:
```bash
docker build -t k8s-monitoring-bot .
docker run -d --name k8s-monitoring-bot \
  --env-file .env \
  -v /path/to/repo:/repo:ro \
  k8s-monitoring-bot
```

## Troubleshooting

### Bot doesn't respond
- Check that the bot is invited to the channel: `/invite @k8s-monitoring-bot`
- Verify Socket Mode is enabled in Slack app settings
- Check logs for errors: `tail -f bot.log`

### Slow responses
- Reduce `MAX_CONTEXT_FILES` to include fewer files
- Use `gpt-4o-mini` instead of `gpt-4o` for faster responses
- Pre-index the repository before starting

### Out of context errors
- The repository is very large; the bot chunks content automatically
- Reduce `MAX_RESPONSE_LENGTH` if responses are too long

### Index not updating
- Delete `.slack-bot-index/` directory to force re-indexing
- Restart the bot after repository changes

## Cost Considerations

- OpenAI API costs vary by model:
  - GPT-4o: ~$0.005 per question (depending on context size)
  - GPT-4o-mini: ~$0.0005 per question
  
- ChromaDB runs locally (no cloud costs)
- Slack is free for Socket Mode

Estimated cost: **$5-20/month** for a team of 10-20 users asking ~100 questions/month.

## Security

- Never commit `.env` file
- Use Slack's Socket Mode (no public webhooks needed)
- API keys should have minimal required permissions
- Bot only reads repository files (no write access)
- All communication is encrypted (Slack ↔ Bot ↔ OpenAI)

## License

This bot is for internal use with the k8s-monitoring-helm repository.

## Support

For issues or questions:
1. Check the logs first
2. Verify environment variables are set correctly
3. Test with a simple question: `@bot what is k8s-monitoring-helm?`
4. Ask in your team's Slack channel
