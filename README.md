# the-one-who-rules-them-all

Master orchestration repository for a multi-repository, polyglot architecture built with **Git Submodules** and **Docker Compose v2**.

The project follows a strict **BUILD vs. RUN** separation:
- **Each service repository owns BUILD**: `Dockerfile`, runtime configuration, and application source code.
- **This master repository owns RUN**: `compose.yaml`, `compose.dev.yaml`, `compose.prod.yaml`, Nginx gateway (`infra/`), databases, shared `.env`, `Makefile`, architecture docs (`docs/`), and cross-service schemas (`contracts/`).

---

## Service Naming Table

| Fun Name | Path | Real Role | Language / Stack | Host Port | Profile |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `the-one-who-rules-them-all` | `/` | Master Orchestrator, Gateway & Infra | Docker Compose v2, Nginx, Make | `8080` | *(core)* |
| `the-one-who-dutifully-keeps` | `services/cms` | CMS & Editorial Admin Backend | PHP 8.4 / Laravel 13 (Botble CMS) | `8080` | *(core)* |
| *(reserved)* | `services/fe` | Storefront / Web Frontend | TypeScript / Next.js | `3000` | `fe` |
| *(reserved)* | `services/go` | High-Throughput Core API | Go | `8081` | `go` |
| *(reserved)* | `services/rust` | Compute / Worker Service | Rust | `8082` | `rust` |
| *(reserved)* | `services/nosql` | Document / NoSQL API Service | Polyglot / NoSQL | `8083` | `nosql` |

---

## Quick Start

### 1. Clone with Submodules
```bash
git clone --recurse-submodules git@github.com:risky2k1/the-one-who-rules-them-all.git
cd the-one-who-rules-them-all
```
*(If you already cloned without `--recurse-submodules`, run `make sync`.)*

### 2. Configure Environment
```bash
cp .env.example .env
```

### 3. Start the Stack
```bash
make up
```

### 4. First-Time CMS Setup
Once `mysql`, `redis`, `cms`, and `nginx` are healthy (`make ps`):
```bash
#### Generate the key and show it, paste it in .env
make artisan cmd="key:generate --show"
make artisan cmd="migrate"
```
Visit **`http://localhost:8080`** (admin panel at **`http://localhost:8080/admin`**).

---

## Development Workflow

Run `make` (or `make help`) to view all available orchestration commands:

| Command | Description |
| :--- | :--- |
| `make up` | Build (if needed) and start the development stack in detached mode |
| `make down` | Stop and remove containers and networks |
| `make restart` | Restart all running containers |
| `make logs` | Tail container logs (filter a single service with `make logs s=cms`) |
| `make ps` | Show container status and healthchecks |
| `make build` | Rebuild service container images |
| `make shell-cms` | Open an interactive `sh` shell inside the `cms` container |
| `make artisan cmd="migrate"` | Run a Laravel Artisan command inside `cms` |
| `make composer cmd="dump-autoload"` | Run a Composer command inside `cms` |
| `make sync` | Pull latest commits for all git submodules |
| `make clean` | Tear down containers, networks, and named volumes |

### Running Production Mode
```bash
make build ENV=prod
make up ENV=prod
```

### Working with Submodules
Each service inside `services/` is an independent Git repository:
1. Commit and push changes inside the service directory (`cd services/cms`) first.
2. Return to the master repository root and commit the updated submodule pointer.
