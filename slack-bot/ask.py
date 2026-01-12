#!/usr/bin/env python3
"""
K8s Monitoring Helm Documentation Search - CLI Version

A simple command-line tool to search the k8s-monitoring-helm documentation.
No Slack, no API, just you and the docs!

Usage:
    python ask.py "How do I configure OTLP destinations?"
    python ask.py --interactive
    python ask.py  # Interactive mode by default
"""

import os
import sys
import argparse
from pathlib import Path

# Add color support for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

# Try to import dependencies
try:
    from repo_indexer import RepoIndexer
    from context_builder import ContextBuilder
except ImportError:
    print(f"{Colors.RED}Error: Missing dependencies.{Colors.END}")
    print("Please install requirements:")
    print("  pip install -r requirements_no_api.txt")
    sys.exit(1)


def format_output(text: str, width: int = 80) -> str:
    """Format text for nice terminal display."""
    import textwrap
    
    lines = text.split('\n')
    formatted = []
    
    for line in lines:
        if line.startswith('#'):
            # Headers
            formatted.append(f"{Colors.BOLD}{Colors.CYAN}{line}{Colors.END}")
        elif line.startswith('```'):
            # Code blocks
            formatted.append(f"{Colors.YELLOW}{line}{Colors.END}")
        elif line.startswith('- ') or line.startswith('• '):
            # Bullet points
            formatted.append(f"{Colors.GREEN}{line}{Colors.END}")
        elif line.strip().startswith('http'):
            # URLs
            formatted.append(f"{Colors.BLUE}{Colors.UNDERLINE}{line}{Colors.END}")
        else:
            # Regular text - wrap it
            if len(line) > width and not line.startswith(' '):
                wrapped = textwrap.fill(line, width=width)
                formatted.append(wrapped)
            else:
                formatted.append(line)
    
    return '\n'.join(formatted)


def print_separator(char: str = "=", width: int = 80):
    """Print a separator line."""
    print(f"{Colors.CYAN}{char * width}{Colors.END}")


def print_doc_section(title: str, content: str, max_length: int = 1000):
    """Print a documentation section nicely."""
    print(f"\n{Colors.BOLD}{Colors.GREEN}📄 {title}{Colors.END}")
    print(f"{Colors.CYAN}{'─' * 80}{Colors.END}")
    
    # Truncate if too long
    if len(content) > max_length:
        content = content[:max_length] + f"\n\n{Colors.YELLOW}... (truncated for readability){Colors.END}"
    
    print(content)


def search_and_display(question: str, repo_path: str, indexer: RepoIndexer, context_builder: ContextBuilder):
    """Search for the answer and display results."""
    
    print(f"\n{Colors.BOLD}{Colors.BLUE}🔍 Searching for:{Colors.END} {question}")
    print_separator()
    
    # Build context
    context = context_builder.build_context(question)
    
    # Display relevant documentation
    if context.get("docs"):
        print(f"\n{Colors.BOLD}{Colors.HEADER}📖 RELEVANT DOCUMENTATION{Colors.END}")
        for i, doc in enumerate(context["docs"][:2], 1):
            print_doc_section(f"{i}. {doc['path']}", doc['content'], max_length=1200)
    
    # Display relevant files from search
    if context.get("relevant_files"):
        print(f"\n{Colors.BOLD}{Colors.HEADER}🔍 CONFIGURATION FILES{Colors.END}")
        for i, file_info in enumerate(context["relevant_files"][:2], 1):
            print_doc_section(f"{i}. {file_info['path']}", file_info['content'], max_length=800)
    
    # Display examples
    if context.get("examples"):
        print(f"\n{Colors.BOLD}{Colors.HEADER}💡 EXAMPLES{Colors.END}")
        for i, example in enumerate(context["examples"][:2], 1):
            print_doc_section(f"{i}. {example['path']}", example['content'], max_length=600)
    
    # Display helpful links
    print(f"\n{Colors.BOLD}{Colors.HEADER}🔗 HELPFUL LINKS{Colors.END}")
    print(f"{Colors.BLUE}• Main Documentation: https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/README.md{Colors.END}")
    
    question_lower = question.lower()
    if "destination" in question_lower or "otlp" in question_lower or "prometheus" in question_lower or "loki" in question_lower:
        print(f"{Colors.BLUE}• Destinations: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/destinations{Colors.END}")
    
    if "collector" in question_lower or "alloy" in question_lower:
        print(f"{Colors.BLUE}• Collectors: https://github.com/grafana/k8s-monitoring-helm/blob/main/charts/k8s-monitoring/docs/Collectors.md{Colors.END}")
    
    if "example" in question_lower:
        print(f"{Colors.BLUE}• Examples: https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/docs/examples{Colors.END}")
    
    print_separator()
    print()


def interactive_mode(repo_path: str, indexer: RepoIndexer, context_builder: ContextBuilder):
    """Run in interactive mode - keep asking questions."""
    print(f"\n{Colors.BOLD}{Colors.HEADER}╔══════════════════════════════════════════════════════════════════════════════╗{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}║          K8s Monitoring Helm Documentation Search - Interactive Mode        ║{Colors.END}")
    print(f"{Colors.BOLD}{Colors.HEADER}╚══════════════════════════════════════════════════════════════════════════════╝{Colors.END}")
    print(f"\n{Colors.CYAN}Type your questions and press Enter. Type 'quit' or 'exit' to leave.{Colors.END}\n")
    
    while True:
        try:
            # Get question
            question = input(f"{Colors.BOLD}{Colors.GREEN}❓ Your question: {Colors.END}").strip()
            
            if not question:
                continue
            
            if question.lower() in ['quit', 'exit', 'q']:
                print(f"\n{Colors.CYAN}👋 Goodbye!{Colors.END}\n")
                break
            
            # Search and display
            search_and_display(question, repo_path, indexer, context_builder)
            
        except KeyboardInterrupt:
            print(f"\n\n{Colors.CYAN}👋 Goodbye!{Colors.END}\n")
            break
        except EOFError:
            print(f"\n\n{Colors.CYAN}👋 Goodbye!{Colors.END}\n")
            break


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Search k8s-monitoring-helm documentation from the command line",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python ask.py "How do I configure OTLP destinations?"
  python ask.py --interactive
  python ask.py -i
        """
    )
    
    parser.add_argument(
        'question',
        nargs='*',
        help='Your question about k8s-monitoring-helm'
    )
    
    parser.add_argument(
        '-i', '--interactive',
        action='store_true',
        help='Run in interactive mode (keep asking questions)'
    )
    
    parser.add_argument(
        '--repo-path',
        default=os.path.dirname(os.path.dirname(__file__)),
        help='Path to k8s-monitoring-helm repository (default: parent directory)'
    )
    
    parser.add_argument(
        '--reindex',
        action='store_true',
        help='Force re-indexing of the repository'
    )
    
    args = parser.parse_args()
    
    # Get repo path
    repo_path = Path(args.repo_path).resolve()
    
    if not repo_path.exists():
        print(f"{Colors.RED}Error: Repository path not found: {repo_path}{Colors.END}")
        print("Use --repo-path to specify the correct path")
        sys.exit(1)
    
    # Initialize indexer
    print(f"{Colors.CYAN}📚 Loading repository from: {repo_path}{Colors.END}")
    indexer = RepoIndexer(str(repo_path))
    
    # Index repository if needed
    index_path = Path(str(repo_path)) / ".slack-bot-index"
    if not index_path.exists() or args.reindex:
        if args.reindex:
            print(f"{Colors.YELLOW}🔄 Re-indexing repository...{Colors.END}")
        else:
            print(f"{Colors.YELLOW}📇 Indexing repository for the first time (this takes ~2 minutes)...{Colors.END}")
        indexer.index_repository()
        print(f"{Colors.GREEN}✓ Indexing complete!{Colors.END}")
    else:
        print(f"{Colors.GREEN}✓ Using existing index{Colors.END}")
    
    # Initialize context builder
    context_builder = ContextBuilder(str(repo_path), indexer)
    
    # Determine mode
    if args.interactive or not args.question:
        # Interactive mode
        interactive_mode(str(repo_path), indexer, context_builder)
    else:
        # Single question mode
        question = ' '.join(args.question)
        search_and_display(question, str(repo_path), indexer, context_builder)


if __name__ == "__main__":
    main()
