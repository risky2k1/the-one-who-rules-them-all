# AGENTS.md — `the-one-who-rules-them-all` (Master Orchestrator)

## Purpose
`the-one-who-rules-them-all` is the **master orchestration repository** for a polyglot multi-repository learning and research system. It coordinates independent microservices mounted via **Git submodules** under `services/` and runs the entire stack via **Docker Compose v2**, shared infrastructure configs (`infra/`), and inter-service contracts (`contracts/`).

## Repository Structure
```text
.
├── compose.yaml          # Base Docker Compose v2 topology & healthchecks
├── compose.dev.yaml      # Development overrides (bind mounts, exposed ports, Xdebug)
├── compose.prod.yaml     # Production overrides (prod target, named volumes, restart policies)
├── .env.example          # Template for all runtime environment variables (no secrets)
├── Makefile              # Self-documenting developer workflow targets
├── .agents/              # AI Agent rules (.agents/rules/) & progressive skills (.agents/skills/)
├── .claude/              # Symlinked rules & skills for Claude Code compatibility
├── contracts/            # Shared API schemas (OpenAPI, Protobuf, JSON Schema)
├── docs/                 # Architecture Decision Records (decisions.md) & system docs
├── infra/
│   ├── mysql/init/       # MySQL initialization scripts
│   └── nginx/            # Reverse proxy & FastCGI gateway configurations
└── services/
    ├── cms/              # Submodule: the-one-who-dutifully-keeps (Botble CMS / Laravel)
    └── fe/               # Submodule: the-one-who-paints-the-world (Next.js / 3D Portfolio)
```

## Service Naming Table

| Fun Name | Path / Submodule | Real Role | Language / Stack | Default Host Port | Compose Profile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `the-one-who-rules-them-all` | `/` (master repo) | System Orchestrator, Gateway, Infra & Contracts | Docker Compose, Nginx, Make | `8080` (Nginx HTTP) | *(core)* |
| `the-one-who-dutifully-keeps` | `services/cms` | Content Management System & Admin Backend | PHP 8.4 / Laravel 13 (Botble CMS) | `8080` (via Nginx) | *(core)* |
| `the-one-who-paints-the-world` | `services/fe` | Public Web Storefront & Interactive 3D Portfolio | TypeScript / Next.js 14 (React Three Fiber) | `3000` | `fe` |
| *(reserved)* | `services/go` | High-Throughput Core API Service | Go | `8081` | `go` |
| *(reserved)* | `services/rust` | Compute / Event Worker Service | Rust | `8082` | `rust` |
| *(reserved)* | `services/nosql` | Document / NoSQL API Service | Polyglot / NoSQL | `8083` | `nosql` |

## Core Conventions & Architectural Rules
1. **Separation of BUILD vs. RUN**:
   - **Each service repo owns BUILD**: Its `Dockerfile` (with `base`, `dev`, `prod` stages), language runtime configs, and `.dockerignore` live inside `services/<name>/`. Service repos must **never** contain `compose.yaml` or `docker-compose.yml`.
   - **Master repo owns RUN**: `compose.yaml`, `compose.dev.yaml`, `compose.prod.yaml`, `infra/`, `.env`, and `Makefile` live exclusively at the master root.
2. **Secrets Management**:
   - Secrets and environment configuration live **only** in the root `.env` file (which is gitignored).
   - Never commit real credentials, API keys, or `.env` files in either the master repo or any service submodule. Always document new variables in `.env.example` using safe placeholders.
3. **One Source of Truth per Data Type**:
   - Each domain entity has a single owning service. For example, editorial content, pages, menus, and media belong to `services/cms` (`mysql`).
   - Services must **never** reach into another service's database tables directly.
4. **Inter-Service Communication**:
   - Services communicate **strictly** over synchronous HTTP/gRPC APIs or asynchronous Redis/message queues over the shared `backend` Docker network.
5. **Shared Specifications in `contracts/`**:
   - Cross-service API specifications (OpenAPI 3.1 YAML, Protobuf `.proto` files, async event schemas) must be defined and versioned inside `contracts/` before or alongside implementation.
6. **Git Submodule Discipline**:
   - Every directory under `services/<name>` is an independent Git repository.
   - Commit and push changes inside `services/<name>` **first**, then stage and commit the updated submodule pointer in the master repository.

## How to Add a New Service as a Submodule
1. **Create and prepare the service repository**:
   - Ensure it contains its own `Dockerfile` (with `dev` and `prod` targets), `.dockerignore`, and `AGENTS.md`.
2. **Add the submodule in the master repository**:
   ```bash
   git submodule add <git-repo-url> services/<service-name>
   ```
3. **Wire the service into Docker Compose**:
   - Add or uncomment the service block in `compose.yaml` under its `profiles: ["<service-name>"]` tag with a pinned base image and healthcheck.
   - Add development bind mounts/ports in `compose.dev.yaml` and production overrides in `compose.prod.yaml`.
4. **Update environment & documentation**:
   - Add any new required environment variables to `.env.example`.
   - Update the Service Naming Table in `AGENTS.md` and `README.md`.
   - Add shared API specs to `contracts/`.
5. **Commit the submodule pointer**:
   ```bash
   git add .gitmodules services/<service-name> compose*.yaml .env.example AGENTS.md README.md
   git commit -m "feat: add <service-name> submodule and compose profile"
   ```
