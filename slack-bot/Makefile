.PHONY: help install run index clean test lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install dependencies
	pip install -r requirements.txt

run: ## Run the bot
	python bot.py

index: ## Force re-index of the repository
	rm -rf .slack-bot-index
	python bot.py

clean: ## Clean up generated files
	rm -rf .slack-bot-index
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete
	find . -type f -name '*.log' -delete

test-context: ## Test context building
	python -c "from context_builder import ContextBuilder; from repo_indexer import RepoIndexer; indexer = RepoIndexer('..'); builder = ContextBuilder('..', indexer); print(builder.build_context('How do I configure OTLP destinations?'))"

lint: ## Lint Python code
	@which pylint > /dev/null || pip install pylint
	pylint *.py

format: ## Format Python code
	@which black > /dev/null || pip install black
	black *.py

check-env: ## Check if environment variables are set
	@test -f .env || (echo "❌ .env file not found. Copy env.example to .env and configure it." && exit 1)
	@echo "✅ .env file exists"
	@grep -q "SLACK_BOT_TOKEN=xoxb-" .env || (echo "⚠️  SLACK_BOT_TOKEN not configured" && exit 1)
	@grep -q "OPENAI_API_KEY=sk-" .env || (echo "⚠️  OPENAI_API_KEY not configured" && exit 1)
	@echo "✅ Environment variables look good"

health: ## Run health check to verify configuration
	python health_check.py

setup: ## Setup the bot (install + check env)
	@make install
	@make check-env
	@echo "✅ Setup complete! Run 'make run' to start the bot."
