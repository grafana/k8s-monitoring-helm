#!/usr/bin/env python3
"""
K8s Monitoring Helm Slack Bot

A Slack bot that answers questions about the k8s-monitoring-helm repository
using AI-powered semantic search and context-aware responses.
"""

import os
import re
import logging
from pathlib import Path
from typing import List, Dict, Optional

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
from dotenv import load_dotenv
import openai

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

# Initialize OpenAI
openai.api_key = os.environ.get("OPENAI_API_KEY")

# Initialize repo indexer and context builder
REPO_PATH = os.environ.get("REPO_PATH", os.path.dirname(os.path.dirname(__file__)))
indexer = RepoIndexer(REPO_PATH)
context_builder = ContextBuilder(REPO_PATH, indexer)

# Configuration
BOT_NAME = os.environ.get("BOT_NAME", "k8s-monitoring-bot")
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-4o")
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


def build_system_prompt() -> str:
    """Build the system prompt for the AI assistant."""
    return """You are a helpful assistant for the k8s-monitoring-helm repository. 
You help users understand how to configure and use the Grafana Kubernetes Monitoring Helm chart.

Key areas you help with:
- Configuring destinations (Prometheus, Loki, OTLP/Tempo, Pyroscope)
- Setting up features (cluster metrics, pod logs, traces, profiling, etc.)
- Configuring Alloy collectors
- Understanding the chart structure and values
- Troubleshooting common issues
- Migration guidance

Guidelines:
1. Provide clear, concise answers with examples when helpful
2. Reference specific documentation or configuration files when relevant
3. Use YAML examples for configuration questions
4. If you're not certain about something, say so
5. Keep responses focused and practical
6. Include links to relevant documentation when available

Base documentation URL: https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/

When providing YAML examples, format them as code blocks."""


def generate_response(question: str, context: Dict) -> str:
    """Generate a response using OpenAI with repository context."""
    try:
        # Build the context message
        context_parts = []
        
        if context.get("relevant_files"):
            context_parts.append("Relevant files from the repository:\n")
            for file_info in context["relevant_files"]:
                context_parts.append(f"\n--- {file_info['path']} ---")
                context_parts.append(file_info['content'])
        
        if context.get("docs"):
            context_parts.append("\n\nRelevant documentation:\n")
            for doc in context["docs"]:
                context_parts.append(f"\n--- {doc['path']} ---")
                context_parts.append(doc['content'])
        
        context_text = "\n".join(context_parts)
        
        # Call OpenAI API
        response = openai.chat.completions.create(
            model=OPENAI_MODEL,
            messages=[
                {"role": "system", "content": build_system_prompt()},
                {"role": "user", "content": f"Context from repository:\n\n{context_text}\n\nQuestion: {question}"}
            ],
            temperature=0.7,
            max_tokens=2000
        )
        
        answer = response.choices[0].message.content
        
        # Truncate if too long
        if len(answer) > MAX_RESPONSE_LENGTH:
            answer = answer[:MAX_RESPONSE_LENGTH] + "\n\n...(response truncated)"
        
        return answer
        
    except Exception as e:
        logger.error(f"Error generating response: {e}", exc_info=True)
        return f"I encountered an error while processing your question: {str(e)}\n\nPlease try rephrasing your question or check the documentation at: https://github.com/grafana/k8s-monitoring-helm"


def format_slack_response(response: str) -> str:
    """Format the response for Slack with proper markdown."""
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
        question = clean_question(event["text"], event["bot_id"] if "bot_id" in event else "")
        
        logger.info(f"Question from {user_id}: {question}")
        
        # Send a "thinking" message
        thinking_msg = client.chat_postMessage(
            channel=channel_id,
            thread_ts=thread_ts,
            text="🤔 Let me search the repository for an answer..."
        )
        
        # Build context from repository
        context = context_builder.build_context(question)
        
        # Generate response
        response = generate_response(question, context)
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
            text="🤔 Let me search the repository for an answer..."
        )
        
        # Build context from repository
        context_data = context_builder.build_context(question)
        
        # Generate response
        response = generate_response(question, context_data)
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
*{BOT_NAME} - K8s Monitoring Helm Assistant*

I can help you with questions about the k8s-monitoring-helm repository!

*How to ask questions:*
• Mention me: `@{BOT_NAME}` followed by your question
• Ask in any channel where I'm present (I'll detect questions about k8s, helm, monitoring, etc.)
• Use the `/k8s-help` command for this help message

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
"""
    
    respond(help_text)


def main():
    """Main function to start the bot."""
    logger.info(f"Starting {BOT_NAME}...")
    
    # Initialize the repository index
    logger.info("Indexing repository...")
    if os.environ.get("ENABLE_VECTOR_SEARCH", "true").lower() == "true":
        indexer.index_repository()
    logger.info("Repository indexed successfully")
    
    # Start the bot
    handler = SocketModeHandler(app, os.environ.get("SLACK_APP_TOKEN"))
    logger.info(f"{BOT_NAME} is running!")
    handler.start()


if __name__ == "__main__":
    main()
