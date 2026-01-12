#!/usr/bin/env python3
"""
K8s Monitoring Helm Slack Bot - No External API Version

A Slack bot that answers questions about the k8s-monitoring-helm repository
using only local semantic search without any LLM API calls.

This version:
- Uses local embeddings (sentence-transformers)
- Returns relevant documentation directly
- No OpenAI or other LLM API required
- Zero API costs
"""

import os
import re
import logging
from pathlib import Path
from typing import List, Dict, Optional

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
from dotenv import load_dotenv

from repo_indexer import RepoIndexer
from context_builder import ContextBuilder

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Slack app
app = App(token=os.environ.get("SLACK_BOT_TOKEN"))

# Initialize repo indexer and context builder
REPO_PATH = os.environ.get("REPO_PATH", os.path.dirname(os.path.dirname(__file__)))
indexer = RepoIndexer(REPO_PATH)
context_builder = ContextBuilder(REPO_PATH, indexer)

# Configuration
BOT_NAME = os.environ.get("BOT_NAME", "k8s-monitoring-bot")
MAX_RESPONSE_LENGTH = int(os.environ.get("MAX_RESPONSE_LENGTH", "3000"))
MONITORED_CHANNELS = os.environ.get("MONITORED_CHANNELS", "").split(",") if os.environ.get("MONITORED_CHANNELS") else []


def is_question_for_bot(text: str, bot_user_id: str) -> bool:
    """Check if the message is directed at the bot or is a question."""
    # Check for direct mention
    if f"<@{bot_user_id}>" in text:
        return True
    
    # Check for bot name mention
    if BOT_NAME.lower() in text.lower():
        return True
    
    # Check if it's a question (ends with ?)
    if "?" in text:
        # Check if it's about helm, k8s, monitoring, destinations, etc.
        keywords = ["helm", "k8s", "kubernetes", "monitoring", "otlp", "destination", 
                   "prometheus", "loki", "tempo", "alloy", "collector", "metric", "log", "trace"]
        if any(keyword in text.lower() for keyword in keywords):
            return True
    
    return False


def clean_question(text: str, bot_user_id: str) -> str:
    """Remove bot mentions and clean up the question."""
    # Remove bot mention
    text = re.sub(f"<@{bot_user_id}>", "", text)
    # Remove extra whitespace
    text = " ".join(text.split())
    return text.strip()


def extract_code_blocks(content: str) -> List[str]:
    """Extract code blocks from markdown content."""
    # Find all code blocks
    pattern = r'```[\w]*\n(.*?)```'
    blocks = re.findall(pattern, content, re.DOTALL)
    return blocks


def format_documentation_section(doc: Dict, max_length: int = 1500) -> str:
    """Format a documentation section for display."""
    path = doc['path']
    content = doc['content']
    
    # Truncate if too long
    if len(content) > max_length:
        content = content[:max_length] + "\n\n_(truncated)_"
    
    # Format as a nice section
    section = f"*{path}*\n\n{content}"
    return section


def generate_response_local(question: str, context: Dict) -> str:
    """Generate a response using only local search results (no LLM API)."""
    try:
        response_parts = []
        
        # Introduction
        response_parts.append(f"📚 Here's what I found about: _{question}_\n")
        
        # Add relevant documentation
        if context.get("docs"):
            response_parts.append("*📖 Relevant Documentation:*\n")
            for i, doc in enumerate(context["docs"][:2], 1):
                section = format_documentation_section(doc, max_length=1000)
                response_parts.append(f"{i}. {section}\n")
        
        # Add relevant files from semantic search
        if context.get("relevant_files"):
            response_parts.append("\n*🔍 Related Configuration:*\n")
            for i, file_info in enumerate(context["relevant_files"][:2], 1):
                section = format_documentation_section(file_info, max_length=800)
                response_parts.append(f"{i}. {section}\n")
        
        # Add examples
        if context.get("examples"):
            response_parts.append("\n*💡 Examples:*\n")
            for i, example in enumerate(context["examples"][:2], 1):
                section = format_documentation_section(example, max_length=600)
                response_parts.append(f"{i}. {section}\n")
        
        # Add helpful links
        response_parts.append("\n*🔗 Helpful Links:*")
        response_parts.append("• Main Documentation: https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/README.md")
        
        # Add specific links based on keywords
        question_lower = question.lower()
        if "destination" in question_lower or "otlp" in question_lower or "prometheus" in question_lower or "loki" in question_lower:
            response_parts.append("• Destinations: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/destinations")
        
        if "collector" in question_lower or "alloy" in question_lower:
            response_parts.append("• Collectors: https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/Collectors.md")
        
        if "example" in question_lower:
            response_parts.append("• Examples: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples")
        
        # Build final response
        response = "\n".join(response_parts)
        
        # Truncate if too long
        if len(response) > MAX_RESPONSE_LENGTH:
            response = response[:MAX_RESPONSE_LENGTH] + "\n\n_(response truncated)_"
        
        # Add footer
        response += "\n\n_💬 Tip: Ask follow-up questions or request specific examples!_"
        
        return response
        
    except Exception as e:
        logger.error(f"Error generating response: {e}", exc_info=True)
        return (
            f"❌ I encountered an error while searching: {str(e)}\n\n"
            "Please check the documentation at: "
            "https://github.com/grafana/k8s-monitoring-helm"
        )


def format_slack_response(response: str) -> str:
    """Format the response for Slack with proper markdown."""
    # Slack uses different markdown than standard markdown
    # Convert markdown code blocks to Slack format
    response = re.sub(r'```yaml\n', '```\n', response)
    response = re.sub(r'```(\w+)\n', '```\n', response)
    
    return response


@app.event("app_mention")
def handle_mention(event, say, client):
    """Handle direct mentions of the bot."""
    try:
        user_id = event["user"]
        channel_id = event["channel"]
        thread_ts = event.get("thread_ts", event["ts"])
        question = clean_question(event["text"], event.get("bot_id", ""))
        
        logger.info(f"Question from {user_id}: {question}")
        
        # Send a "thinking" message
        thinking_msg = client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="🔍 Searching the repository..."
        )
        
        # Build context from repository
        context = context_builder.build_context(question)
        
        # Generate response (no API call)
        response = generate_response_local(question, context)
        formatted_response = format_slack_response(response)
        
        # Update the message with the response
        client.chat_update(
            channel=channel_id,
            ts=thinking_msg["ts"],
            text=formatted_response
        )
        
        logger.info(f"Response sent for question: {question[:50]}...")
        
    except Exception as e:
        logger.error(f"Error handling mention: {e}", exc_info=True)
        say(f"Sorry, I encountered an error: {str(e)}")


@app.message(re.compile(r".*", re.DOTALL))
def handle_message(message, say, client, context):
    """Handle messages in channels where the bot is present."""
    try:
        # Skip bot messages
        if message.get("bot_id"):
            return
        
        # Skip if in a monitored channel list and not in it
        channel_id = message.get("channel")
        if MONITORED_CHANNELS and channel_id not in MONITORED_CHANNELS:
            return
        
        # Get bot user ID
        bot_user_id = context.get("bot_user_id")
        text = message.get("text", "")
        
        # Check if this is a question for the bot
        if not is_question_for_bot(text, bot_user_id):
            return
        
        user_id = message["user"]
        thread_ts = message.get("thread_ts", message["ts"])
        question = clean_question(text, bot_user_id)
        
        logger.info(f"Question from {user_id}: {question}")
        
        # Send a "thinking" message
        thinking_msg = client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="🔍 Searching the repository..."
        )
        
        # Build context from repository
        context_data = context_builder.build_context(question)
        
        # Generate response (no API call)
        response = generate_response_local(question, context_data)
        formatted_response = format_slack_response(response)
        
        # Update the message with the response
        client.chat_update(
            channel=channel_id,
            ts=thinking_msg["ts"],
            text=formatted_response
        )
        
        logger.info(f"Response sent for question: {question[:50]}...")
        
    except Exception as e:
        logger.error(f"Error handling message: {e}", exc_info=True)


@app.command("/k8s-help")
def handle_help_command(ack, command, respond):
    """Handle the /k8s-help slash command."""
    ack()
    
    help_text = f"""
*{BOT_NAME} - K8s Monitoring Helm Assistant* (No-API Version)

I can help you find documentation and examples from the k8s-monitoring-helm repository!

*How to ask questions:*
• Mention me: `@{BOT_NAME}` followed by your question
• Ask in any channel where I'm present (I'll detect questions about k8s, helm, monitoring, etc.)
• Use the `/k8s-help` command for this help message

*What I do:*
• Search documentation using semantic search
• Find relevant examples
• Show you the exact configuration files
• Provide links to full documentation

*Example questions:*
• How do I configure multiple OTLP destinations?
• What's the difference between alloy-metrics and alloy-logs collectors?
• How do I enable pod logs collection?
• Can I send traces to Tempo using this chart?
• How do I configure authentication for Prometheus?

*Useful links:*
• Main README: https://github.com/grafana/k8s-monitoring-helm
• Documentation: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs
• Examples: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples

*Note:* This bot uses local search only (no AI generation), so responses include direct documentation excerpts.
"""
    
    respond(help_text)


@app.command("/k8s-search")
def handle_search_command(ack, command, respond):
    """Handle the /k8s-search slash command for direct searches."""
    ack()
    
    query = command.get("text", "").strip()
    
    if not query:
        respond("Usage: `/k8s-search <your question>`\n\nExample: `/k8s-search how to configure OTLP`")
        return
    
    try:
        # Build context from repository
        context = context_builder.build_context(query)
        
        # Generate response
        response = generate_response_local(query, context)
        formatted_response = format_slack_response(response)
        
        respond(formatted_response)
        
    except Exception as e:
        logger.error(f"Error handling search command: {e}", exc_info=True)
        respond(f"❌ Error: {str(e)}")


def main():
    """Main function to start the bot."""
    logger.info(f"Starting {BOT_NAME} (No-API Version)...")
    
    # Initialize the repository index
    logger.info("Indexing repository...")
    if os.environ.get("ENABLE_VECTOR_SEARCH", "true").lower() == "true":
        indexer.index_repository()
    logger.info("Repository indexed successfully")
    
    logger.info("✅ No external API required - using local search only")
    
    # Start the bot
    handler = SocketModeHandler(app, os.environ.get("SLACK_APP_TOKEN"))
    logger.info(f"{BOT_NAME} is running!")
    handler.start()


if __name__ == "__main__":
    main()
