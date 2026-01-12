"""
Context Builder

Builds context for AI responses by searching the repository
and gathering relevant files and documentation.
"""

import os
import logging
import re
from pathlib import Path
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)


class ContextBuilder:
    """Builds context from repository for answering questions."""
    
    # Important documentation files
    PRIORITY_DOCS = [
        "charts/k8s-monitoring/README.md",
        "charts/k8s-monitoring/docs/destinations/README.md",
        "charts/k8s-monitoring/docs/Features.md",
        "charts/k8s-monitoring/docs/Collectors.md",
    ]
    
    # Keyword to documentation mapping
    DOC_KEYWORDS = {
        "otlp": "charts/k8s-monitoring/docs/destinations/otlp.md",
        "prometheus": "charts/k8s-monitoring/docs/destinations/prometheus.md",
        "loki": "charts/k8s-monitoring/docs/destinations/loki.md",
        "pyroscope": "charts/k8s-monitoring/docs/destinations/pyroscope.md",
        "destination": "charts/k8s-monitoring/docs/destinations/README.md",
        "collector": "charts/k8s-monitoring/docs/Collectors.md",
        "alloy": "charts/k8s-monitoring/docs/Collectors.md",
        "migration": "charts/k8s-monitoring/docs/Migration.md",
        "troubleshoot": "charts/k8s-monitoring/docs/Troubleshooting.md",
    }
    
    def __init__(self, repo_path: str, indexer):
        """Initialize the context builder."""
        self.repo_path = Path(repo_path)
        self.indexer = indexer
        self.max_context_files = int(os.environ.get("MAX_CONTEXT_FILES", "5"))
    
    def extract_keywords(self, question: str) -> List[str]:
        """Extract relevant keywords from the question."""
        # Convert to lowercase
        question_lower = question.lower()
        
        # Find matching keywords
        keywords = []
        for keyword in self.DOC_KEYWORDS.keys():
            if keyword in question_lower:
                keywords.append(keyword)
        
        return keywords
    
    def get_relevant_docs(self, question: str) -> List[Dict]:
        """Get relevant documentation based on the question."""
        docs = []
        keywords = self.extract_keywords(question)
        
        # Add keyword-specific docs
        for keyword in keywords:
            if keyword in self.DOC_KEYWORDS:
                doc_path = self.DOC_KEYWORDS[keyword]
                content = self.indexer.get_file_content(doc_path)
                if content:
                    # Limit doc size
                    if len(content) > 5000:
                        content = content[:5000] + "\n\n...(truncated)"
                    docs.append({
                        "path": doc_path,
                        "content": content,
                        "reason": f"Matched keyword: {keyword}"
                    })
        
        return docs
    
    def get_values_schema(self) -> Optional[Dict]:
        """Get relevant parts of values.yaml based on question."""
        values_path = "charts/k8s-monitoring/values.yaml"
        content = self.indexer.get_file_content(values_path)
        
        if not content:
            return None
        
        return {
            "path": values_path,
            "content": content[:3000] + "\n\n...(truncated)" if len(content) > 3000 else content,
            "reason": "Main configuration schema"
        }
    
    def search_examples(self, question: str) -> List[Dict]:
        """Search for relevant examples."""
        examples_dir = self.repo_path / "charts/k8s-monitoring/docs/examples"
        
        if not examples_dir.exists():
            return []
        
        # Use semantic search to find relevant examples
        search_results = self.indexer.search(question, n_results=3)
        
        examples = []
        for result in search_results:
            file_path = result['metadata']['file_path']
            
            # Only include examples
            if 'examples' in file_path:
                content = self.indexer.get_file_content(file_path)
                if content:
                    examples.append({
                        "path": file_path,
                        "content": content[:2000] + "\n\n...(truncated)" if len(content) > 2000 else content,
                        "reason": "Example matching your question"
                    })
        
        return examples[:2]  # Limit to 2 examples
    
    def build_context(self, question: str) -> Dict:
        """Build comprehensive context for answering the question."""
        logger.info(f"Building context for question: {question[:100]}")
        
        context = {
            "question": question,
            "relevant_files": [],
            "docs": [],
            "examples": []
        }
        
        # 1. Get relevant docs based on keywords
        docs = self.get_relevant_docs(question)
        context["docs"].extend(docs)
        
        # 2. Semantic search for relevant content
        if os.environ.get("ENABLE_VECTOR_SEARCH", "true").lower() == "true":
            search_results = self.indexer.search(question, n_results=self.max_context_files)
            
            for result in search_results:
                file_path = result['metadata']['file_path']
                
                # Skip if already included in docs
                if any(doc['path'] == file_path for doc in context['docs']):
                    continue
                
                # Get full file content for small files, chunk for large files
                if result['metadata']['total_chunks'] <= 3:
                    content = self.indexer.get_file_content(file_path)
                else:
                    content = result['content']
                
                if content:
                    context["relevant_files"].append({
                        "path": file_path,
                        "content": content[:2000] + "\n\n...(truncated)" if len(content) > 2000 else content,
                        "reason": "Semantic match"
                    })
        
        # 3. Add values.yaml if relevant
        if any(keyword in question.lower() for keyword in ["configure", "config", "values", "how to", "setup", "enable"]):
            values_info = self.get_values_schema()
            if values_info and not any(f['path'] == values_info['path'] for f in context['relevant_files']):
                context["relevant_files"].append(values_info)
        
        # 4. Search for relevant examples
        examples = self.search_examples(question)
        context["examples"].extend(examples)
        
        # Limit total context
        context["relevant_files"] = context["relevant_files"][:self.max_context_files]
        
        logger.info(f"Context built: {len(context['docs'])} docs, {len(context['relevant_files'])} files, {len(context['examples'])} examples")
        
        return context
