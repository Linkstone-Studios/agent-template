# Agent Template - Development Commands
# Usage: make <target>
# Run `make help` to see all available commands

.PHONY: help setup flutter-% db-% supabase-% agent-% deploy-%

.DEFAULT_GOAL := help

# ============================================
# HELP
# ============================================

help: ## Show this help message
	@echo "Agent Template - Development Commands"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================
# SETUP
# ============================================

setup: ## Initial project setup (install all dependencies)
	@echo "📦 Installing Flutter dependencies..."
	cd flutter && flutter pub get
	@echo "📦 Installing Supabase DB dependencies..."
	cd supabase/db && npm install
	@echo "✅ Setup complete!"

# ============================================
# FLUTTER COMMANDS (flutter/)
# ============================================

flutter-run: ## Run the Flutter app
	cd flutter && flutter run

flutter-build: ## Run build_runner to generate code (Freezed, Riverpod, etc.)
	cd flutter && dart run build_runner build --delete-conflicting-outputs

flutter-watch: ## Run build_runner in watch mode
	cd flutter && dart run build_runner watch --delete-conflicting-outputs

flutter-test: ## Run Flutter tests
	cd flutter && flutter test

flutter-analyze: ## Run Flutter analyzer
	cd flutter && flutter analyze

flutter-clean: ## Clean Flutter build artifacts
	cd flutter && flutter clean

flutter-get: ## Get Flutter dependencies
	cd flutter && flutter pub get

# ============================================
# AGENT COMMANDS (hermes-agent/)
# ============================================

agent-up: ## Start the Hermes Agent locally with Docker
	cd hermes-agent && docker-compose up -d

agent-down: ## Stop the Hermes Agent
	cd hermes-agent && docker-compose down

agent-logs: ## View Hermes Agent logs
	cd hermes-agent && docker-compose logs -f

agent-restart: ## Restart the Hermes Agent
	cd hermes-agent && docker-compose restart

# ============================================
# DATABASE COMMANDS (Drizzle)
# ============================================

db-generate: ## Generate Drizzle migration from schema changes
	cd supabase/db && npm run db:generate

db-push: ## Push/apply migrations to Supabase database
	cd supabase/db && npm run db:push

db-migrate: ## Alias for db-push
	cd supabase/db && npm run db:migrate

db-studio: ## Open Drizzle Studio (visual DB inspector)
	cd supabase/db && npm run db:studio

db-gen-dart: ## Generate Dart models from database schema
	cd supabase/db && npm run gen:dart

# ============================================
# SUPABASE COMMANDS
# ============================================

supabase-start: ## Start local Supabase instance
	supabase start

supabase-stop: ## Stop local Supabase instance
	supabase stop

supabase-status: ## Check Supabase status
	supabase status

# ============================================
# DEPLOY COMMANDS
# ============================================

deploy-functions: ## Deploy all Edge Functions (set your project ref first)
	supabase functions deploy YOUR_FUNCTION_NAME --project-ref YOUR_PROJECT_REF --no-verify-jwt

deploy-web-build: ## Build Flutter web for production
	@echo "📦 Building Flutter web..."
	@cd flutter && flutter build web --release --pwa-strategy=none

deploy-web: deploy-web-build ## Deploy Flutter web to Firebase Hosting
	firebase deploy --only hosting

deploy-web-preview: deploy-web-build ## Preview deployment (creates temporary URL)
	firebase hosting:channel:deploy preview

# ============================================
# COMBINED WORKFLOWS
# ============================================

full-build: flutter-get flutter-build ## Get deps and run build_runner
	@echo "✅ Full build complete!"