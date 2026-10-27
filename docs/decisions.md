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

---

## ADR-0002: Kids Math Practice Embedded in FE Route and CMS Plugin Without New Service

- **Date:** 2026-10-27
- **Status:** Accepted

### Context
The kids math practice feature requires:
- An interactive web application for children (with 3D visual rewards and interactive cube counting) and a management portal for parents.
- Content authoring, parent/child account management, curriculum trees, question generation, and progress tracking backend.

We evaluated whether to create a dedicated backend microservice (`services/kids` in Go/Python/Node) or to integrate within existing services:
- `services/fe` (Next.js 14 App Router, React Three Fiber) is already configured for rich 3D graphics, responsive layouts, and Tailwind styling.
- `services/cms` (Botble CMS, Laravel 13, PHP 8.4) already provides robust administrative CRUD, Sanctum token authentication, relational MySQL persistence, and REST API foundation.

### Decision
1. **Frontend Integration**:
   - The kids math practice experience lives inside `services/fe` under the `/kids` route (for children) and `/kids/parent` (for parents).
   - No separate frontend service or repository is created.
   - Base paths are encapsulated so they can be adapted or moved if necessary.

2. **Backend Integration**:
   - The kids math domain is implemented as a self-contained Botble CMS plugin (`services/cms/platform/plugins/kids`).
   - Pure PHP domain logic (generators, answer matching, adaptive difficulty, review scheduling) lives in `src/Engine/` decoupled from database and framework dependencies.
   - REST endpoints are exposed under `/api/v1/kids/*` using Sanctum tokens (`parent`, `device`, `kid`).
   - Administrative management (topics, templates, parents, reports) integrates into the Botble admin interface via standard form and table builders.

3. **No New Compose Services**:
   - No additional Docker containers or microservices are added to `compose.yaml`.
   - Communication between `fe` and `cms` flows through existing Nginx gateway / Next.js internal API rewrites.

### Consequences
- **Positive:** Reuses existing infrastructure, authentication primitives, database, and admin UI without increasing Docker Compose operational footprint or host memory overhead.
- **Positive:** Pure domain engine remains highly testable via fast unit tests without requiring database booting.
- **Positive:** Shared OpenAPI contract (`contracts/openapi/kids.v1.yaml`) establishes a clear inter-service boundary between `fe` and `cms`.
- **Trade-off:** CMS database handles kids data alongside editorial content (mitigated by strict table prefixing `kids_*` and clean plugin isolation).

