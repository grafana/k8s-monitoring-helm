"""
Repository Indexer

Indexes the k8s-monitoring-helm repository for semantic search.
Uses ChromaDB for vector storage and sentence-transformers for embeddings.
"""

import os
import logging
from pathlib import Path
from typing import List, Dict, Optional
import yaml

import chromadb
from chromadb.utils import embedding_functions
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)


class RepoIndexer:
    """Indexes repository files for semantic search."""
    
    # File extensions to index
    INDEXABLE_EXTENSIONS = {
        '.md', '.yaml', '.yml', '.tpl', '.txt', 
        '.go', '.py', '.sh', '.json'
    }
    
    # Directories to skip
    SKIP_DIRS = {
        '.git', 'node_modules', '__pycache__', '.pytest_cache',
        'venv', '.venv', 'dist', 'build', '.tox'
    }
    
    def __init__(self, repo_path: str, persist_dir: str = None):
        """Initialize the indexer."""
        self.repo_path = Path(repo_path)
        self.persist_dir = persist_dir or str(self.repo_path / ".slack-bot-index")
        
        # Initialize ChromaDB
        self.client = chromadb.PersistentClient(path=self.persist_dir)
        
        # Initialize embedding function
        self.embedding_function = embedding_functions.SentenceTransformerEmbeddingFunction(
            model_name="all-MiniLM-L6-v2"
        )
        
        # Get or create collection
        self.collection = self.client.get_or_create_collection(
            name="k8s_monitoring_helm",
            embedding_function=self.embedding_function
        )
    
    def should_index_file(self, file_path: Path) -> bool:
        """Check if a file should be indexed."""
        # Check extension
        if file_path.suffix not in self.INDEXABLE_EXTENSIONS:
            return False
        
        # Check if in skip directory
        for part in file_path.parts:
            if part in self.SKIP_DIRS:
                return False
        
        # Skip lock files
        if file_path.name.endswith('.lock'):
            return False
        
        return True
    
    def chunk_text(self, text: str, max_chunk_size: int = 1000) -> List[str]:
        """Split text into chunks for better embeddings."""
        # Simple chunking by lines
        lines = text.split('\n')
        chunks = []
        current_chunk = []
        current_size = 0
        
        for line in lines:
            line_size = len(line)
            if current_size + line_size > max_chunk_size and current_chunk:
                chunks.append('\n'.join(current_chunk))
                current_chunk = [line]
                current_size = line_size
            else:
                current_chunk.append(line)
                current_size += line_size
        
        if current_chunk:
            chunks.append('\n'.join(current_chunk))
        
        return chunks
    
    def index_file(self, file_path: Path):
        """Index a single file."""
        try:
            # Read file content
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            
            # Skip empty files
            if not content.strip():
                return
            
            # Get relative path
            rel_path = str(file_path.relative_to(self.repo_path))
            
            # Chunk the content
            chunks = self.chunk_text(content)
            
            # Add to collection
            for i, chunk in enumerate(chunks):
                doc_id = f"{rel_path}::chunk_{i}"
                
                # Add metadata
                metadata = {
                    "file_path": rel_path,
                    "chunk_index": i,
                    "total_chunks": len(chunks),
                    "file_type": file_path.suffix,
                }
                
                self.collection.upsert(
                    ids=[doc_id],
                    documents=[chunk],
                    metadatas=[metadata]
                )
            
            logger.debug(f"Indexed {rel_path} ({len(chunks)} chunks)")
            
        except Exception as e:
            logger.warning(f"Failed to index {file_path}: {e}")
    
    def index_repository(self):
        """Index all files in the repository."""
        logger.info(f"Indexing repository at {self.repo_path}")
        
        indexed_count = 0
        skipped_count = 0
        
        # Walk through repository
        for root, dirs, files in os.walk(self.repo_path):
            # Skip directories
            dirs[:] = [d for d in dirs if d not in self.SKIP_DIRS]
            
            root_path = Path(root)
            
            for file in files:
                file_path = root_path / file
                
                if self.should_index_file(file_path):
                    self.index_file(file_path)
                    indexed_count += 1
                else:
                    skipped_count += 1
        
        logger.info(f"Indexing complete: {indexed_count} files indexed, {skipped_count} skipped")
    
    def search(self, query: str, n_results: int = 5) -> List[Dict]:
        """Search for relevant documents."""
        try:
            results = self.collection.query(
                query_texts=[query],
                n_results=n_results
            )
            
            # Format results
            formatted_results = []
            if results['documents'] and results['documents'][0]:
                for i in range(len(results['documents'][0])):
                    formatted_results.append({
                        'content': results['documents'][0][i],
                        'metadata': results['metadatas'][0][i],
                        'distance': results['distances'][0][i] if 'distances' in results else None
                    })
            
            return formatted_results
            
        except Exception as e:
            logger.error(f"Search error: {e}", exc_info=True)
            return []
    
    def get_file_content(self, file_path: str) -> Optional[str]:
        """Get the full content of a file."""
        try:
            full_path = self.repo_path / file_path
            with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                return f.read()
        except Exception as e:
            logger.warning(f"Failed to read {file_path}: {e}")
            return None
