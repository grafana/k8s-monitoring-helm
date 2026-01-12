#!/usr/bin/env python3
"""
Health check script for the K8s Monitoring Helm Slack Bot

This script verifies that:
1. All required environment variables are set
2. The repository path exists and is valid
3. OpenAI API key is valid
4. Slack tokens are properly formatted
5. Required Python packages are installed
"""

import os
import sys
from pathlib import Path

# Colors for terminal output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
RESET = '\033[0m'


def check(condition, message):
    """Print check result."""
    if condition:
        print(f"{GREEN}✓{RESET} {message}")
        return True
    else:
        print(f"{RED}✗{RESET} {message}")
        return False


def warn(message):
    """Print warning."""
    print(f"{YELLOW}⚠{RESET} {message}")


def main():
    """Run health checks."""
    print("K8s Monitoring Helm Slack Bot - Health Check")
    print("=" * 50)
    print()
    
    all_checks_passed = True
    
    # Check for .env file
    print("Environment Configuration:")
    print("-" * 50)
    
    env_file = Path(".env")
    if check(env_file.exists(), ".env file exists"):
        # Load .env file
        try:
            from dotenv import load_dotenv
            load_dotenv()
        except ImportError:
            warn("python-dotenv not installed, skipping .env loading")
    else:
        all_checks_passed = False
        print(f"  → Run: cp env.example .env")
    
    print()
    
    # Check environment variables
    print("Required Environment Variables:")
    print("-" * 50)
    
    required_vars = {
        'SLACK_BOT_TOKEN': 'xoxb-',
        'SLACK_APP_TOKEN': 'xapp-',
        'SLACK_SIGNING_SECRET': None,
        'OPENAI_API_KEY': 'sk-',
    }
    
    for var, prefix in required_vars.items():
        value = os.environ.get(var, '')
        
        if not value:
            check(False, f"{var} is set")
            all_checks_passed = False
        elif 'example' in value or 'your-' in value or 'here' in value:
            check(False, f"{var} is configured (still contains placeholder)")
            all_checks_passed = False
        elif prefix and not value.startswith(prefix):
            check(False, f"{var} has correct format (should start with '{prefix}')")
            all_checks_passed = False
        else:
            check(True, f"{var} is set and formatted correctly")
    
    print()
    
    # Check optional variables
    print("Optional Configuration:")
    print("-" * 50)
    
    optional_vars = {
        'REPO_PATH': 'Path to k8s-monitoring-helm repository',
        'OPENAI_MODEL': 'OpenAI model to use',
        'BOT_NAME': 'Name of the bot',
        'MAX_CONTEXT_FILES': 'Maximum files in context',
    }
    
    for var, description in optional_vars.items():
        value = os.environ.get(var, '')
        if value:
            print(f"{GREEN}✓{RESET} {var} = {value}")
        else:
            print(f"  {var}: not set (will use default)")
    
    print()
    
    # Check repository path
    print("Repository:")
    print("-" * 50)
    
    repo_path = os.environ.get('REPO_PATH', str(Path(__file__).parent.parent))
    repo_path_obj = Path(repo_path)
    
    if check(repo_path_obj.exists(), f"Repository path exists: {repo_path}"):
        values_file = repo_path_obj / "charts" / "k8s-monitoring" / "values.yaml"
        check(values_file.exists(), "values.yaml found (repository structure is valid)")
    else:
        all_checks_passed = False
        print(f"  → Set REPO_PATH in .env to the correct path")
    
    print()
    
    # Check Python packages
    print("Python Dependencies:")
    print("-" * 50)
    
    required_packages = [
        'slack_bolt',
        'slack_sdk',
        'openai',
        'dotenv',
        'chromadb',
        'sentence_transformers',
    ]
    
    for package in required_packages:
        # Map package names
        import_name = package
        if package == 'dotenv':
            import_name = 'dotenv'
        elif package == 'sentence_transformers':
            import_name = 'sentence_transformers'
        
        try:
            __import__(import_name)
            check(True, f"{package} installed")
        except ImportError:
            check(False, f"{package} installed")
            all_checks_passed = False
    
    if not all_checks_passed:
        print()
        print(f"  → Run: pip install -r requirements.txt")
    
    print()
    
    # Check API connectivity (optional)
    if os.environ.get('OPENAI_API_KEY') and 'your-' not in os.environ.get('OPENAI_API_KEY', ''):
        print("API Connectivity:")
        print("-" * 50)
        
        try:
            import openai
            openai.api_key = os.environ.get('OPENAI_API_KEY')
            
            # Try to list models as a simple check
            try:
                client = openai.OpenAI(api_key=os.environ.get('OPENAI_API_KEY'))
                models = client.models.list()
                check(True, "OpenAI API key is valid")
            except Exception as e:
                check(False, f"OpenAI API key is valid: {str(e)}")
                all_checks_passed = False
        except ImportError:
            warn("Cannot test OpenAI API (openai package not installed)")
        
        print()
    
    # Summary
    print("=" * 50)
    if all_checks_passed:
        print(f"{GREEN}✓ All checks passed!{RESET}")
        print()
        print("You're ready to start the bot:")
        print("  python bot.py")
        return 0
    else:
        print(f"{RED}✗ Some checks failed{RESET}")
        print()
        print("Please fix the issues above before starting the bot.")
        print()
        print("Quick fixes:")
        print("  1. Configure .env: nano .env")
        print("  2. Install dependencies: pip install -r requirements.txt")
        print("  3. Set correct REPO_PATH in .env")
        return 1


if __name__ == "__main__":
    sys.exit(main())
