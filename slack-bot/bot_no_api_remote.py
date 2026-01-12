#!/usr/bin/env python3
"""
K8s Monitoring Helm Slack Bot - No API Version with Remote Repo Support

This version can clone and index a remote Git repository instead of
requiring a local copy.
"""

import os
import sys
import shutil
import logging
from pathlib import Path
from typing import Optional
import subprocess

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
from dotenv import load_dotenv

# Import from the main bot
from bot_no_api import (
    generate_response_local,
    format_slack_response,
    is_question_for_bot,
    clean_question,
    app,
    logger
)

from repo_indexer import RepoIndexer
from context_builder import ContextBuilder

# Load environment variables
load_dotenv()

# Configuration
REMOTE_REPO_URL = os.environ.get(
    "REMOTE_REPO_URL",
    "https://github.com/grafana/k8s-monitoring-helm.git"
)
REMOTE_REPO_BRANCH = os.environ.get("REMOTE_REPO_BRANCH", "main")
LOCAL_CLONE_PATH = os.environ.get(
    "LOCAL_CLONE_PATH",
    "/tmp/k8s-monitoring-helm"
)
AUTO_UPDATE_INTERVAL = int(os.environ.get("AUTO_UPDATE_INTERVAL", "3600"))  # seconds


def clone_or_update_repo(url: str, path: str, branch: str = "main") -> bool:
    """Clone a repository or update it if it already exists."""
    path_obj = Path(path)
    
    try:
        if path_obj.exists():
            logger.info(f"Repository exists at {path}, pulling latest changes...")
            # Pull latest changes
            result = subprocess.run(
                ["git", "-C", path, "pull", "origin", branch],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode != 0:
                logger.error(f"Git pull failed: {result.stderr}")
                # Try to re-clone
                logger.info("Removing old clone and re-cloning...")
                shutil.rmtree(path)
                return clone_or_update_repo(url, path, branch)
            
            logger.info("Repository updated successfully")
            return True
            
        else:
            logger.info(f"Cloning repository from {url} to {path}...")
            path_obj.parent.mkdir(parents=True, exist_ok=True)
            
            result = subprocess.run(
                ["git", "clone", "--branch", branch, "--depth", "1", url, path],
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode != 0:
                logger.error(f"Git clone failed: {result.stderr}")
                return False
            
            logger.info("Repository cloned successfully")
            return True
            
    except subprocess.TimeoutExpired:
        logger.error("Git operation timed out")
        return False
    except Exception as e:
        logger.error(f"Error cloning/updating repository: {e}", exc_info=True)
        return False


def setup_remote_repo() -> Optional[str]:
    """Setup the remote repository and return the path."""
    logger.info("Setting up remote repository...")
    
    if clone_or_update_repo(REMOTE_REPO_URL, LOCAL_CLONE_PATH, REMOTE_REPO_BRANCH):
        return LOCAL_CLONE_PATH
    else:
        logger.error("Failed to setup remote repository")
        return None


def main():
    """Main function to start the bot with remote repo support."""
    logger.info("Starting K8s Monitoring Bot (No-API, Remote Repo Version)...")
    
    # Setup remote repository
    repo_path = setup_remote_repo()
    
    if not repo_path:
        logger.error("Cannot start bot without repository")
        sys.exit(1)
    
    logger.info(f"Using repository at: {repo_path}")
    
    # Initialize the repository index
    logger.info("Indexing repository...")
    indexer = RepoIndexer(repo_path)
    
    if os.environ.get("ENABLE_VECTOR_SEARCH", "true").lower() == "true":
        indexer.index_repository()
    
    logger.info("Repository indexed successfully")
    logger.info("✅ No external API required - using local search only")
    logger.info(f"📦 Indexed repository: {REMOTE_REPO_URL} (branch: {REMOTE_REPO_BRANCH})")
    
    # Make indexer and context builder available globally
    # (In a real app, you'd use dependency injection or a context manager)
    import bot_no_api
    bot_no_api.indexer = indexer
    bot_no_api.context_builder = ContextBuilder(repo_path, indexer)
    
    # Start the bot
    handler = SocketModeHandler(app, os.environ.get("SLACK_APP_TOKEN"))
    logger.info("🤖 Bot is running and connected to Slack!")
    
    # TODO: In a production setup, you'd want to periodically update the repo
    # using a background thread or scheduled task
    
    handler.start()


if __name__ == "__main__":
    main()
