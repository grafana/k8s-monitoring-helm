# Command-Line Documentation Search

A simple command-line tool to search the k8s-monitoring-helm documentation. No Slack, no API, just you and the docs!

## Quick Start

### Installation
```bash
cd slack-bot
pip install -r requirements_no_api.txt
```

### Usage

**Interactive Mode (Recommended)**
```bash
python ask.py
```

This opens an interactive prompt where you can keep asking questions:
```
❓ Your question: How do I configure OTLP destinations?
[... shows relevant docs ...]

❓ Your question: Can the URL field take multiple values?
[... shows answer ...]

❓ Your question: quit
```

**Single Question Mode**
```bash
python ask.py "How do I configure OTLP destinations?"
```

Ask one question and get the answer immediately.

## Examples

### Example 1: Interactive Mode
```bash
$ python ask.py --interactive

╔══════════════════════════════════════════════════════════════════════════════╗
║          K8s Monitoring Helm Documentation Search - Interactive Mode        ║
╚══════════════════════════════════════════════════════════════════════════════╝

Type your questions and press Enter. Type 'quit' or 'exit' to leave.

❓ Your question: How do I enable pod logs?

🔍 Searching for: How do I enable pod logs?
================================================================================

📖 RELEVANT DOCUMENTATION

📄 1. charts/k8s-monitoring/values.yaml
────────────────────────────────────────────────────────────────────────────────
podLogs:
  # -- Enable gathering Kubernetes Pod logs.
  # @section -- Features - Pod Logs
  enabled: false

  # -- The destinations where logs will be sent. If empty, all logs-capable 
  # destinations will be used.
  # @section -- Features - Pod Logs
  destinations: []

💡 EXAMPLES

📄 1. charts/k8s-monitoring/docs/examples/pod-logs-basic/values.yaml
────────────────────────────────────────────────────────────────────────────────
podLogs:
  enabled: true
  destinations: []  # Uses all log destinations

🔗 HELPFUL LINKS
• Main Documentation: https://github.com/grafana/k8s-monitoring-helm/...

❓ Your question: quit
👋 Goodbye!
```

### Example 2: Quick Question
```bash
$ python ask.py "Can the URL field take multiple values?"

🔍 Searching for: Can the URL field take multiple values?
================================================================================

📖 RELEVANT DOCUMENTATION

📄 1. charts/k8s-monitoring/docs/destinations/otlp.md
────────────────────────────────────────────────────────────────────────────────
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| url | string | `""` | The URL for the OTLP destination. |

The field is defined as type `string`, which means it accepts a single URL 
value, not a list or array of URLs.
...
```

### Example 3: Force Re-index
```bash
# If the repository has changed
python ask.py --reindex "What are the available destinations?"
```

## Command-Line Options

```
python ask.py [OPTIONS] [QUESTION]

Arguments:
  QUESTION              Your question (if not provided, enters interactive mode)

Options:
  -i, --interactive     Force interactive mode
  --repo-path PATH      Path to k8s-monitoring-helm repository
  --reindex             Force re-indexing the repository
  -h, --help            Show help message
```

## Features

### ✅ What It Does
- Semantic search through all documentation
- Shows relevant configuration files
- Displays examples
- Provides links to full documentation
- Color-coded output for easy reading
- Fast responses (1-2 seconds)

### 🎨 Color-Coded Output
- **Blue headers** - Section titles
- **Green text** - File paths and bullet points
- **Yellow text** - Code blocks and warnings
- **Cyan lines** - Separators
- **Underlined links** - Clickable URLs (in some terminals)

### 💡 Smart Features
- **First-time indexing**: Takes ~2 minutes, then instant
- **Cached index**: Subsequent runs are immediate
- **Auto-complete aware**: Paste questions with quotes or not
- **Keyboard shortcuts**: Ctrl+C or type "quit" to exit

## Use Cases

### Quick Reference
```bash
python ask.py "What's the field name for Prometheus URL?"
```

### Learning Mode
```bash
python ask.py --interactive
# Then explore multiple related topics
```

### Documentation Lookup
```bash
python ask.py "Show me OTLP configuration options"
```

### Example Finding
```bash
python ask.py "Do you have examples with Loki destinations?"
```

## Common Questions

### "It says 'Indexing repository' - is this normal?"
Yes! The first time you run it, it needs to read through all the documentation and create a searchable index. This takes ~2 minutes but only happens once.

### "Can I use this without internet?"
Yes! After the initial indexing, it works completely offline.

### "How is this different from grep?"
This uses semantic search - it finds documents by meaning, not just exact text matches. Ask in natural language!

### "Does this cost money?"
No! It's completely free. No API calls, no subscriptions.

### "Can I search my own fork?"
Yes! Use `--repo-path` to point to your fork:
```bash
python ask.py --repo-path ~/my-fork "your question"
```

## Advanced Usage

### Search Specific Fork
```bash
python ask.py --repo-path ~/my-k8s-fork "How do I configure destinations?"
```

### Pipe to File
```bash
python ask.py "Show all destination types" > answer.txt
```

### Use in Scripts
```bash
#!/bin/bash
# Get documentation programmatically
answer=$(python ask.py "What is the default scrapeInterval?")
echo "Found: $answer"
```

### Create Alias
Add to your `.bashrc` or `.zshrc`:
```bash
alias k8s-ask='python ~/path/to/slack-bot/ask.py'
```

Then use:
```bash
k8s-ask "How do I enable traces?"
```

## Comparison with Other Tools

| Feature | ask.py | grep | GitHub Search | Slack Bot |
|---------|--------|------|---------------|-----------|
| **Semantic Search** | ✅ | ❌ | ❌ | ✅ |
| **Offline** | ✅ | ✅ | ❌ | ❌ |
| **Natural Language** | ✅ | ❌ | ❌ | ✅ |
| **Speed** | Fast | Instant | Slow | Fast |
| **Cost** | Free | Free | Free | Free/Paid |
| **Setup** | 1 command | None | None | Complex |

## Tips & Tricks

### 1. Ask Natural Questions
```bash
# Good
python ask.py "How do I send metrics to Prometheus?"

# Also works, but less effective
python ask.py "prometheus metrics configuration"
```

### 2. Be Specific
```bash
# Better results
python ask.py "How do I configure authentication for Loki destinations?"

# vs less specific
python ask.py "authentication"
```

### 3. Use Interactive Mode for Related Questions
If you're exploring a topic, use interactive mode to ask follow-up questions without re-indexing each time.

### 4. Combine with Other Tools
```bash
# Find the answer, then grep for specifics
python ask.py "Where is scrapeInterval configured?" | grep -A5 "scrapeInterval"
```

### 5. Save Useful Queries
Create a cheat sheet:
```bash
# destinations.sh
python ask.py "What destination types are available?"
python ask.py "How do I configure multiple destinations?"
python ask.py "Can I send different telemetry types to different destinations?"
```

## Troubleshooting

### "ModuleNotFoundError: No module named 'chromadb'"
```bash
pip install -r requirements_no_api.txt
```

### "Repository path not found"
```bash
# Make sure you're in the right directory
cd /path/to/k8s-monitoring-helm/slack-bot
python ask.py "your question"

# Or specify the path
python ask.py --repo-path /path/to/k8s-monitoring-helm "your question"
```

### "No results found"
Try rephrasing your question or using different keywords:
```bash
# Instead of
python ask.py "OTLP URL configuration"

# Try
python ask.py "How do I set the URL for OTLP destinations?"
```

### "Indexing takes forever"
The first indexing takes 2-3 minutes for the full repository. This is normal. Subsequent runs use the cached index and are instant.

To rebuild the index:
```bash
python ask.py --reindex "your question"
```

## Integration Ideas

### VS Code Task
`.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Search k8s docs",
      "type": "shell",
      "command": "python",
      "args": ["slack-bot/ask.py", "--interactive"]
    }
  ]
}
```

### Git Alias
```bash
git config --global alias.k8s-docs '!python slack-bot/ask.py'
```

Then:
```bash
git k8s-docs "your question"
```

### Makefile Target
```makefile
.PHONY: docs
docs:
	@python slack-bot/ask.py --interactive
```

## Performance

- **First run**: ~2 minutes (indexing)
- **Subsequent runs**: ~1-2 seconds per query
- **Memory usage**: ~500MB (for embeddings)
- **Disk usage**: ~100MB (for index)

## Comparison: CLI vs Slack Bot

| Feature | CLI (ask.py) | Slack Bot |
|---------|-------------|-----------|
| **Setup** | 1 command | Slack app + config |
| **Usage** | Terminal | Slack channels |
| **Speed** | 1-2 seconds | 1-2 seconds |
| **Sharing** | Copy/paste | Built-in |
| **Team Use** | Individual | Collaborative |
| **Best For** | Personal quick lookup | Team documentation |

**Recommendation**: Use CLI for personal use, Slack bot for team collaboration!

## Summary

**ask.py** is perfect when you:
- Need quick answers without opening Slack
- Want to search while coding
- Are working offline
- Prefer command-line tools
- Want instant documentation lookup

**Three ways to use it:**
```bash
# Interactive (recommended for exploration)
python ask.py

# Single question (quick lookup)
python ask.py "your question here"

# Scripting (automation)
answer=$(python ask.py "your question")
```

Fast, free, and no Slack required! 🚀
