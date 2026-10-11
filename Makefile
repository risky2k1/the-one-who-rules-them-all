.DEFAULT_GOAL := help

ENV ?= dev
COMPOSE := docker compose -f compose.yaml -f compose.$(ENV).yaml

.PHONY: help up down restart logs ps build shell-cms artisan composer sync clean

help: ## Show available Make targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

up: ## Start the stack in detached mode (default ENV=dev)
	$(COMPOSE) up -d

down: ## Stop and remove containers and networks
	$(COMPOSE) down

restart: ## Restart all running services
	$(COMPOSE) restart

logs: ## Follow container logs (optional: make logs s=cms)
	$(COMPOSE) logs -f $(s)

ps: ## List running containers and health status
	$(COMPOSE) ps

build: ## Build or rebuild service images
	$(COMPOSE) build

shell-cms: ## Open an interactive shell inside the cms container
	$(COMPOSE) exec cms sh

artisan: ## Run an Artisan command in cms (usage: make artisan cmd="migrate")
	@if [ -z "$(cmd)" ]; then echo "Usage: make artisan cmd=\"<command>\""; exit 1; fi
	$(COMPOSE) exec -u www-data cms php artisan $(cmd)

composer: ## Run a Composer command in cms (usage: make composer cmd="dump-autoload")
	@if [ -z "$(cmd)" ]; then echo "Usage: make composer cmd=\"<command>\""; exit 1; fi
	$(COMPOSE) exec cms composer $(cmd)

sync: ## Initialize and update all git submodules to latest remote commit
	git submodule update --init --recursive --remote

clean: ## Stop containers and remove volumes, networks, and orphans
	$(COMPOSE) down -v --remove-orphans
