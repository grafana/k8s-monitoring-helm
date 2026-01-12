# Quick Documentation Search Tool - Setup for Grafana Team

A simple command-line tool to ask questions about the k8s-monitoring-helm chart and get instant answers from the documentation.

## What This Does

Type a question like "How do I configure OTLP destinations?" and it instantly searches through all the Helm chart documentation and shows you the relevant info.

**No Slack setup needed. No API keys needed. Just works!**

---

## Setup (5 Minutes)

### Step 1: Get the Code

Open your terminal and run:

```bash
# Clone the repo (or use your existing clone)
git clone https://github.com/grafana/k8s-monitoring-helm.git
cd k8s-monitoring-helm

# Switch to the tooling branch
git checkout slack-bot-tooling

# Go to the slack-bot folder
cd slack-bot
```

### Step 2: Install Python Packages

```bash
pip3 install -r requirements_no_api.txt
```

**Note**: This installs some Python packages on your computer. Takes about 1-2 minutes.

### Step 3: Run It!

```bash
python3 ask.py
```

That's it! You'll see:

```
╔══════════════════════════════════════════════════════════════════════════════╗
║          K8s Monitoring Helm Documentation Search - Interactive Mode        ║
╚══════════════════════════════════════════════════════════════════════════════╝

Type your questions and press Enter. Type 'quit' or 'exit' to leave.

❓ Your question: _
```

**First time only**: The first run takes 2-3 minutes to index all the documentation. After that, it's instant!

---

## How to Use

### Interactive Mode (Ask Multiple Questions)

```bash
cd ~/k8s-monitoring-helm/slack-bot
python3 ask.py
```

Then just type your questions:
```
❓ Your question: How do I configure OTLP destinations?
[... shows answer with docs and examples ...]

❓ Your question: Can the URL field take multiple values?
[... shows answer ...]

❓ Your question: quit
👋 Goodbye!
```

### Quick Single Question

```bash
python3 ask.py "How do I enable pod logs?"
```

Gets the answer immediately and exits.

---

## Example Questions You Can Ask

**Configuration:**
- "How do I configure multiple OTLP destinations?"
- "What authentication options are available for Prometheus?"
- "How do I set up Loki destinations?"

**Features:**
- "How do I enable cluster metrics?"
- "How do I collect pod logs?"
- "What collectors are available?"

**Troubleshooting:**
- "Why aren't my logs showing up?"
- "How do I debug Alloy?"

**Examples:**
- "Show me examples of OTLP configuration"
- "Do you have examples with authentication?"

---

## Tips

### Make It Easy to Run From Anywhere

Add this to your `~/.zshrc` or `~/.bashrc`:

```bash
alias k8s-ask='python3 ~/k8s-monitoring-helm/slack-bot/ask.py'
```

Then reload:
```bash
source ~/.zshrc
```

Now from any directory:
```bash
k8s-ask "your question"
```

### Keep It Updated

When the chart documentation gets updated:

```bash
cd ~/k8s-monitoring-helm
git pull origin main
cd slack-bot
python3 ask.py --reindex "your question"
```

The `--reindex` flag rebuilds the search index with the new docs.

---

## Troubleshooting

### "Module not found" Error
```bash
cd ~/k8s-monitoring-helm/slack-bot
pip3 install -r requirements_no_api.txt
```

### "Repository path not found"
Make sure you're in the right directory:
```bash
cd ~/k8s-monitoring-helm/slack-bot
python3 ask.py
```

### First Run Is Slow
The first time takes 2-3 minutes to index all the documentation. This is normal. After that, all queries are instant (1-2 seconds).

### Not Finding Good Answers
Try rephrasing your question:
- Instead of: "OTLP URL"
- Try: "How do I configure the URL for OTLP destinations?"

---

## What It Searches

The tool searches through:
- All documentation files (`docs/` folder)
- Configuration schemas (`values.yaml`)
- Examples (`examples/` folder)
- Integration tests (for real-world configs)

It uses **semantic search**, meaning it finds documents by meaning, not just exact text matches.

---

## Why This Branch Won't Be Merged

This is an **internal tool** for the Grafana team, not part of the official Helm chart.

The `slack-bot-tooling` branch will stay separate so:
- ✅ The main chart repo stays clean
- ✅ Users don't see internal tooling
- ✅ We can update the tool independently
- ✅ Anyone at Grafana can check out this branch and use it

---

## Quick Reference Card

```bash
# Setup (one time)
git clone https://github.com/grafana/k8s-monitoring-helm.git
cd k8s-monitoring-helm
git checkout slack-bot-tooling
cd slack-bot
pip3 install -r requirements_no_api.txt

# Use it (anytime)
python3 ask.py                              # Interactive mode
python3 ask.py "your question"              # Quick answer
python3 ask.py --help                       # Show all options

# Optional: Create alias for easy access
echo 'alias k8s-ask="python3 ~/k8s-monitoring-helm/slack-bot/ask.py"' >> ~/.zshrc
source ~/.zshrc
k8s-ask "your question"                     # Use from anywhere
```

---

## Cost

**Free!** No API keys, no subscriptions, no cloud services. Just Python running on your laptop.

---

## Support

Questions about the tool? Ask in the Grafana k8s-monitoring team channel, or just use the tool to ask questions about itself! 😄

```bash
python3 ask.py "How does this search tool work?"
```

---

## Summary

1. **Clone the repo**: `git clone https://github.com/grafana/k8s-monitoring-helm.git`
2. **Get the branch**: `git checkout slack-bot-tooling`
3. **Install packages**: `pip3 install -r slack-bot/requirements_no_api.txt`
4. **Run it**: `python3 slack-bot/ask.py`
5. **Ask questions**: Type your question and press Enter!

**Time to set up**: 5 minutes  
**Time to get answers**: 1-2 seconds  
**Cost**: $0  

Enjoy instant documentation search! 🚀
