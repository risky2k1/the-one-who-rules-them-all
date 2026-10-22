.DEFAULT_GOAL := help

ENV ?= local
COMPOSE := docker compose -f compose.yaml -f compose.$(ENV).yaml

# Allow passing arguments without cmd="...", e.g.: make artisan cms:install
ifeq ($(firstword $(MAKECMDGOALS)),$(filter $(firstword $(MAKECMDGOALS)),artisan composer pnpm-fe))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  %:
	@:
endif
ARTISAN_CMD := $(if $(cmd),$(cmd),$(RUN_ARGS))
COMPOSER_CMD := $(if $(cmd),$(cmd),$(RUN_ARGS))
PNPM_CMD := $(if $(cmd),$(cmd),$(RUN_ARGS))

.PHONY: help up down restart logs ps build shell-cms artisan composer shell-fe pnpm-fe sync clean

help: ## Show available Make targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

up: ## Start the stack in detached mode (default ENV=local)
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

artisan: ## Run an Artisan command in cms (usage: make artisan cms:install or make artisan cmd="migrate")
	@if [ -z "$(strip $(ARTISAN_CMD))" ]; then echo "Usage: make artisan <command> (or cmd=\"<command>\")"; exit 1; fi
	$(COMPOSE) exec -u www-data cms php artisan $(ARTISAN_CMD)

composer: ## Run a Composer command in cms (usage: make composer dump-autoload)
	@if [ -z "$(strip $(COMPOSER_CMD))" ]; then echo "Usage: make composer <command> (or cmd=\"<command>\")"; exit 1; fi
	$(COMPOSE) exec cms composer $(COMPOSER_CMD)

shell-fe: ## Open an interactive shell inside the fe container
	$(COMPOSE) exec fe sh

pnpm-fe: ## Run a pnpm command in fe (usage: make pnpm-fe test)
	@if [ -z "$(strip $(PNPM_CMD))" ]; then echo "Usage: make pnpm-fe <command> (or cmd=\"<command>\")"; exit 1; fi
	$(COMPOSE) exec fe pnpm $(PNPM_CMD)

sync: ## Initialize and update all git submodules to latest remote commit
	git submodule update --init --recursive --remote

clean: ## Stop containers and remove volumes, networks, and orphans
	$(COMPOSE) down -v --remove-orphans
