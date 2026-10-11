# Architecture Decision Records (ADR)

This document records key architectural and operational decisions made for `the-one-who-rules-them-all`.

---

## ADR-0001: Master Owns Docker Compose (RUN) While Services Own Dockerfiles (BUILD)

- **Date:** 2026-10-11
- **Status:** Accepted

### Context
The system is structured as a multi-repository polyglot project where a master repository (`the-one-who-rules-them-all`) coordinates multiple independent service repositories (`services/cms`, and future Next.js, Go, Rust, and NoSQL services) via Git submodules.

Initially, framework scaffolding tools (such as Laravel Sail in `services/cms`) bundle their own standalone `docker-compose.yml`, database containers, and network definitions inside the service repository. When multiple services each define their own Compose stack:
- Port collisions occur on `80`, `3306`, and `6379`.
- Infrastructure containers (MySQL, Redis, Nginx) are duplicated across repos.
- Environment variables and secrets become scattered across multiple `.env` files.
- Cross-service networking requires manual external bridge wiring.

### Decision
We enforce a strict **BUILD vs. RUN** separation of responsibilities:

1. **Each Service Repository Owns BUILD**:
   - Houses its own multi-stage `Dockerfile` (`base`, `dev`, `prod` stages), language/runtime configurations (`php.ini`, `entrypoint.sh`), and `.dockerignore`.
   - Contains **no** `compose.yaml` or `docker-compose.yml`.
   - Can be built and tested as an isolated container image in CI (`docker build --target prod -f docker/php/Dockerfile .`).

2. **The Master Repository Owns RUN**:
   - Houses `compose.yaml` (base topology), `compose.dev.yaml` (local bind mounts, exposed ports, debuggers), and `compose.prod.yaml` (production targets, restart policies, named volumes).
   - Manages shared infrastructure (`infra/nginx/`, `infra/mysql/`), a single shared Docker network (`backend`), and a single root `.env` file.
   - Uses Docker Compose `profiles` so future services (`fe`, `go`, `rust`, `nosql`) plug into the stack without altering existing core services.

### Consequences
- **Positive:** Single command (`make up`) boots the entire integrated stack with deterministic healthchecks and zero port/network conflicts.
- **Positive:** Service repositories remain self-contained for building container images and can be deployed independently to any container orchestrator.
- **Positive:** Secrets live in one gitignored `.env` file at the master root.
- **Trade-off:** Running a service locally with its backing infrastructure requires cloning the master repo (or running `docker build` + `docker run` manually).
