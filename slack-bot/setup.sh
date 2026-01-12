#!/bin/bash

# Setup script for K8s Monitoring Helm Slack Bot

set -e

echo "🤖 K8s Monitoring Helm Slack Bot Setup"
echo "======================================"
echo ""

# Check Python version
echo "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.9 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "✅ Found Python $PYTHON_VERSION"

# Create virtual environment
if [ ! -d "venv" ]; then
    echo ""
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo ""
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
echo "✅ Dependencies installed"

# Check for .env file
echo ""
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found"
    echo "Creating .env from env.example..."
    cp env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "⚠️  IMPORTANT: You need to edit .env and add your credentials:"
    echo "   - SLACK_BOT_TOKEN (from Slack app OAuth & Permissions)"
    echo "   - SLACK_APP_TOKEN (from Slack app Socket Mode)"
    echo "   - SLACK_SIGNING_SECRET (from Slack app Basic Information)"
    echo "   - OPENAI_API_KEY (from OpenAI platform)"
    echo ""
    echo "Run: nano .env"
    echo ""
else
    echo "✅ .env file exists"
    
    # Check if credentials are configured
    if grep -q "your-bot-token-here" .env || grep -q "your-openai-api-key-here" .env; then
        echo "⚠️  .env file needs to be configured with your credentials"
        echo ""
    else
        echo "✅ .env appears to be configured"
    fi
fi

echo ""
echo "======================================"
echo "Setup complete! 🎉"
echo ""
echo "Next steps:"
echo "1. Configure your .env file with Slack and OpenAI credentials"
echo "2. Run: source venv/bin/activate"
echo "3. Run: python bot.py"
echo ""
echo "Or use the Makefile:"
echo "  make setup    - Install and check configuration"
echo "  make run      - Start the bot"
echo "  make help     - See all available commands"
echo ""
