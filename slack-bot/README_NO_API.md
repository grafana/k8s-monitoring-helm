# K8s Monitoring Helm Slack Bot - No API Version

A Slack bot that answers questions about the k8s-monitoring-helm repository using **only local semantic search** - no external API calls required!

## Key Differences from Full Version

| Feature | Full Version (bot.py) | No-API Version (bot_no_api.py) |
|---------|----------------------|--------------------------------|
| **LLM API** | ✅ OpenAI GPT-4 | ❌ None required |
| **Responses** | AI-generated answers | Direct documentation excerpts |
| **Cost** | ~$5-20/month | $0 (completely free!) |
| **Setup** | Requires OpenAI API key | Only Slack tokens needed |
| **Quality** | Natural language answers | Raw documentation (accurate) |
| **Speed** | 3-5 seconds | 1-2 seconds (faster!) |
| **Offline** | No | Yes (after initial indexing) |

## How It Works

Instead of using an LLM to generate responses, this version:

1. **Indexes** the repository using local embeddings (sentence-transformers)
2. **Searches** semantically using ChromaDB (runs locally)
3. **Returns** the most relevant documentation sections directly
4. **Formats** them nicely with links and context

**Result**: You get the exact documentation that matches your question, without any AI interpretation or API costs!

## Quick Start

### 1. Install Dependencies

```bash
cd slack-bot
pip install -r requirements_no_api.txt
```

**Note**: No OpenAI package needed!

### 2. Configure Environment

```bash
cp env_no_api.example .env
nano .env
```

Only add Slack credentials (no OpenAI key!):
```env
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_APP_TOKEN=xapp-your-token
SLACK_SIGNING_SECRET=your-secret
REPO_PATH=/path/to/k8s-monitoring-helm
```

### 3. Run the Bot

```bash
python bot_no_api.py
```

## Example Interaction

**User**: `@bot How do I configure multiple OTLP destinations?`

**Bot Response**:
```
📚 Here's what I found about: How do I configure multiple OTLP destinations?

📖 Relevant Documentation:

1. charts/k8s-monitoring/docs/destinations/README.md

You can specify multiple destinations in the `destinations` section 
of the configuration file. Each destination must have a name and a type...

2. charts/k8s-monitoring/values.yaml

destinations: []
# -- The list of destinations where telemetry data will be sent...

🔍 Related Configuration:

1. charts/k8s-monitoring/tests/integration/split-destinations/values.yaml

destinations:
  - name: allTraces
    type: otlp
    url: all-traces-tempo.svc:4317
  - name: productionTraces
    type: otlp
    url: prod-traces-tempo.svc:4317
...

🔗 Helpful Links:
• Main Documentation: https://github.com/grafana/k8s-monitoring-helm/...
• Destinations: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/destinations

💬 Tip: Ask follow-up questions or request specific examples!
```

## Features

### ✅ What It Has
- Semantic search using local embeddings
- Returns exact documentation and examples
- Zero API costs
- Fast response times (1-2 seconds)
- Works offline (after initial setup)
- All the same Slack integration features
- Automatic question detection
- Thread support
- Slash commands: `/k8s-help`, `/k8s-search`

### ❌ What It Doesn't Have
- Natural language generation
- Answer synthesis across multiple sources
- Conversational refinement
- Ability to explain or simplify complex topics

## When to Use This Version

**Use No-API Version If:**
- ✅ You want zero ongoing costs
- ✅ You prefer raw documentation over AI summaries
- ✅ You need fast, direct answers
- ✅ You're concerned about API reliability
- ✅ You want complete data privacy (nothing leaves your server)
- ✅ You don't have budget for OpenAI API

**Use Full Version If:**
- ✅ You want natural language explanations
- ✅ You need synthesis of multiple sources
- ✅ You want the bot to "understand" complex questions
- ✅ You're okay with ~$5-20/month API costs
- ✅ You want conversational follow-ups

## Commands

### In Channel
```
@bot How do I enable pod logs?
@bot What's the difference between collectors?
```

### Slash Commands
```
/k8s-help           - Show help message
/k8s-search <query> - Direct search without mention
```

## Deployment

Same deployment options as the full version:

### Docker
```bash
docker build -t k8s-monitoring-bot-no-api -f Dockerfile.no-api .
docker run -d --env-file .env \
  -v /path/to/repo:/repo:ro \
  k8s-monitoring-bot-no-api
```

### Systemd Service
```bash
# Use the provided service file, but run bot_no_api.py
sudo systemctl enable k8s-monitoring-bot
sudo systemctl start k8s-monitoring-bot
```

### Direct Run
```bash
python bot_no_api.py
```

## Performance

- **First run**: 2-3 minutes (indexing repository)
- **Subsequent starts**: Instant (uses cached index)
- **Query response**: 1-2 seconds
- **Memory usage**: ~500MB (for embeddings)
- **Disk usage**: ~100MB (for vector index)

## Hybrid Approach

You can also use **both versions**:

1. Use the no-API version for common questions (fast, free)
2. Use the full version for complex questions that need AI (when needed)

Just run both bots with different names:
```env
# bot_no_api.py
BOT_NAME=k8s-docs-bot

# bot.py
BOT_NAME=k8s-ai-bot
```

Then:
- `@k8s-docs-bot` → Fast documentation lookup
- `@k8s-ai-bot` → AI-powered explanations

## Customization

### Adjust Response Length
```env
MAX_RESPONSE_LENGTH=5000  # Show more documentation
```

### Adjust Search Results
```env
MAX_CONTEXT_FILES=10  # Include more files in search
```

### Disable Vector Search (Use Simple Keyword Search)
```env
ENABLE_VECTOR_SEARCH=false  # Faster, but less accurate
```

## Comparison Example

**Question**: "Can the URL field take multiple values?"

### No-API Version Response:
```
📖 Relevant Documentation:

charts/k8s-monitoring/docs/destinations/otlp.md

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| url | string | `""` | The URL for the OTLP destination. |

The field is defined as type `string`, which means it accepts 
a single URL value, not a list or array of URLs.
```

### Full Version Response:
```
Based on the documentation, the `url` field in the OTLP destination 
configuration **cannot take multiple values**. 

The field is defined as type `string`, which means it accepts a single 
URL value, not a list or array of URLs.

If you need to send data to multiple OTLP endpoints, you would need to 
define multiple OTLP destination configurations, each with its own `url` 
field pointing to a different endpoint.

Here's an example:

```yaml
destinations:
  - name: tempo
    type: otlp
    url: http://tempo.example.com:4317
  - name: otlpgateway
    type: otlp
    url: https://gateway.example.com:4317
```

Would you like me to show you more examples of multi-destination 
configurations?
```

**Both are correct** - the no-API version gives you the raw facts, the full version explains and provides context!

## Troubleshooting

### "Module not found" errors
```bash
pip install -r requirements_no_api.txt
```

### Slow first response
- First run indexes the repository (2-3 minutes)
- Subsequent queries are fast (~1 second)

### Not finding relevant docs
- Make sure `ENABLE_VECTOR_SEARCH=true`
- Try rephrasing your question
- Check that the repository path is correct

## Cost Savings

With 100 questions/month:
- **Full version**: ~$5-15/month (OpenAI API)
- **No-API version**: $0/month

With 1000 questions/month:
- **Full version**: ~$50-150/month
- **No-API version**: $0/month

## Limitations

1. **No AI Understanding**: The bot doesn't "understand" your question, it just finds similar text
2. **No Synthesis**: Can't combine information from multiple sources into one answer
3. **Raw Documentation**: You get markdown/YAML as-is, not formatted explanations
4. **No Conversational Memory**: Each question is independent

## Advantages

1. **Zero Cost**: Completely free to run
2. **Fast**: 1-2 second responses
3. **Private**: All processing is local
4. **Reliable**: No external API dependencies
5. **Accurate**: Returns actual documentation, not AI interpretation
6. **Offline**: Works without internet (after setup)

## Summary

The no-API version is perfect if you:
- Want a documentation search bot without ongoing costs
- Prefer direct documentation over AI summaries
- Need fast, reliable responses
- Want complete control and privacy

It's essentially a **smart documentation search engine** that lives in Slack!

## License

Same as the full version - for internal use with k8s-monitoring-helm.
