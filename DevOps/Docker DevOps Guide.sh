Docker DevOps Guide

## Table of Contents
1. [Docker & Containerization](#docker)
2. [DevOps & CI/CD](#devops)
3. [Cloud (AWS)](#aws)
4. [Observability & Production Reliability](#observability)
5. [Security](#security)

---

# 1. DOCKER & CONTAINERIZATION

## Docker Architecture

Docker uses a **client-server architecture** with three main components:

```
┌─────────────────────────────────────────────────────────┐
│                     DOCKER ARCHITECTURE                  │
│                                                          │
│  ┌──────────┐         ┌──────────────────────────────┐  │
│  │  Docker   │  REST   │       Docker Daemon          │  │
│  │  Client   │──API───▶│       (dockerd)              │  │
│  │  (CLI)    │         │                              │  │
│  └──────────┘         │  ┌────────┐ ┌────────┐       │  │
│                        │  │Container│ │Container│      │  │
│  Commands:             │  │   A    │ │   B    │       │  │
│  docker build          │  └────────┘ └────────┘       │  │
│  docker run            │                              │  │
│  docker pull           │  ┌─────────────────────┐     │  │
│                        │  │   Image Cache        │    │  │
│                        │  └─────────────────────┘     │  │
│                        └──────────┬───────────────────┘  │
│                                   │                      │
│                        ┌──────────▼───────────────────┐  │
│                        │    Docker Registry           │  │
│                        │    (Docker Hub / ECR / GCR)  │  │
│                        └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Key Components:**
- **Docker Client**: CLI that sends commands to the daemon
- **Docker Daemon (dockerd)**: Builds, runs, manages containers
- **Docker Registry**: Stores Docker images (Docker Hub, ECR, etc.)
- **containerd**: Container runtime that manages container lifecycle
- **runc**: Low-level OCI runtime that actually creates containers

```bash
# Check Docker system info
docker info

# See all running components
docker version

# The flow when you run "docker run nginx":
# 1. CLI sends request to dockerd via REST API
# 2. dockerd checks if image exists locally
# 3. If not, pulls from registry
# 4. dockerd instructs containerd to create container
# 5. containerd calls runc to start the container process
# 6. Container runs as isolated process with its own namespaces
```

---

## Dockerfile Optimization

### Bad Dockerfile (Unoptimized)

```dockerfile
# ❌ BAD - Unoptimized Dockerfile
FROM node:18

WORKDIR /app

# Copies EVERYTHING - busts cache on any file change
COPY . .

RUN npm install

# Running as root (security risk)
EXPOSE 3000
CMD ["node", "server.js"]
```

### Good Dockerfile (Optimized)

```dockerfile
# ✅ GOOD - Optimized Dockerfile
# 1. Use specific version tags (not "latest")
FROM node:18.17-alpine AS base

# 2. Set working directory
WORKDIR /app

# 3. Copy dependency files FIRST (layer caching)
COPY package.json package-lock.json ./

# 4. Install dependencies (cached unless package*.json changes)
RUN npm ci --only=production

# 5. Copy source code AFTER installing deps
COPY src/ ./src/

# 6. Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# 7. Change ownership and switch user
RUN chown -R appuser:appgroup /app
USER appuser

# 8. Use EXPOSE for documentation
EXPOSE 3000

# 9. Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# 10. Use exec form for CMD (proper signal handling)
CMD ["node", "src/server.js"]
```

### Layer Caching Deep Dive

```dockerfile
# Each instruction creates a LAYER
# Docker caches layers and reuses them if nothing changed

# Layer 1: Base image (cached unless base image changes)
FROM node:18-alpine

# Layer 2: Working directory (almost always cached)
WORKDIR /app

# Layer 3: Package files (cached unless package.json changes)
COPY package.json package-lock.json ./

# Layer 4: Dependencies (cached unless Layer 3 changed)
# npm ci is better than npm install for reproducibility
RUN npm ci --only=production

# Layer 5: Source code (changes frequently - put LAST)
COPY . .

# KEY INSIGHT: If Layer 5 changes, only Layer 5 rebuilds
# If Layer 3 changes, Layers 3, 4, and 5 ALL rebuild
```

```bash
# Inspect image layers
docker history myapp:latest

# Build with build cache information
docker build --progress=plain -t myapp .

# Reduce image size
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### .dockerignore

```
# .dockerignore - ALWAYS include this
node_modules
npm-debug.log
.git
.gitignore
.env
.env.*
Dockerfile
docker-compose*.yml
README.md
.vscode
.idea
coverage
tests
__tests__
*.test.js
*.spec.js
.nyc_output
dist
build
```

---

## Multi-Stage Builds

Multi-stage builds dramatically reduce final image size by separating build and runtime environments.

### Node.js / TypeScript Example

```dockerfile
# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# ============================================
# Stage 2: Build (TypeScript compilation)
# ============================================
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
# Prune dev dependencies after build
RUN npm prune --production

# ============================================
# Stage 3: Production Runtime
# ============================================
FROM node:18-alpine AS runner
WORKDIR /app

# Security: run as non-root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 appuser

# Copy ONLY what's needed for production
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:nodejs /app/package.json ./

USER appuser
EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "dist/server.js"]
```

### Go Example (Even More Dramatic Size Reduction)

```dockerfile
# Stage 1: Build
FROM golang:1.21-alpine AS builder
WORKDIR /app

# Cache go modules
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Stage 2: Runtime - using scratch (empty image!)
FROM scratch
# Import CA certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/main /main

EXPOSE 8080
ENTRYPOINT ["/main"]

# Result: Final image is ~10-15MB vs ~800MB with golang base
```

### Python Example

```dockerfile
# Stage 1: Build wheels
FROM python:3.11-slim AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim AS runner
WORKDIR /app

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Install only the pre-built wheels
COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*

COPY --chown=appuser:appgroup . .
USER appuser

CMD ["python", "app.py"]
```

```
Size Comparison:
┌────────────────────────────────────────────┐
│ Without Multi-stage:                       │
│   node:18          ~900MB                  │
│   golang:1.21      ~800MB                  │
│   python:3.11      ~900MB                  │
│                                            │
│ With Multi-stage:                          │
│   node:18-alpine   ~150MB                  │
│   scratch (Go)     ~10MB                   │
│   python:3.11-slim ~120MB                  │
└────────────────────────────────────────────┘
```

---

## Image Layering

```
┌─────────────────────────────────────────────┐
│         Container Layer (R/W)               │  ← Writable
├─────────────────────────────────────────────┤
│  Layer 5: CMD ["node", "server.js"]         │  ← Read-only
├─────────────────────────────────────────────┤
│  Layer 4: COPY . .                          │  ← Read-only
├─────────────────────────────────────────────┤
│  Layer 3: RUN npm install                   │  ← Read-only
├─────────────────────────────────────────────┤
│  Layer 2: COPY package.json .               │  ← Read-only
├─────────────────────────────────────────────┤
│  Layer 1: FROM node:18-alpine               │  ← Read-only
└─────────────────────────────────────────────┘

Key concepts:
• Each Dockerfile instruction creates a layer
• Layers are cached and shared between images
• Union File System (OverlayFS) stacks layers
• Only the top container layer is writable
• Deleting a file in upper layer just "whiteouts" it
  (the file still exists in lower layers!)
```

```bash
# Inspect layers of an image
docker inspect myapp:latest | jq '.[0].RootFS.Layers'

# See layer sizes
docker history myapp:latest --no-trunc

# Common MISTAKE: file still in earlier layer
# ❌ BAD:
RUN curl -o bigfile.tar.gz https://example.com/bigfile.tar.gz
RUN tar xzf bigfile.tar.gz
RUN rm bigfile.tar.gz   # File still in the layer above!

# ✅ GOOD: single layer
RUN curl -o bigfile.tar.gz https://example.com/bigfile.tar.gz && \
    tar xzf bigfile.tar.gz && \
    rm bigfile.tar.gz
```

---

## Volume Management

```bash
# ========================================
# Three types of mounts in Docker
# ========================================

# 1. VOLUMES (Docker-managed, recommended for persistent data)
docker volume create mydata
docker run -v mydata:/app/data nginx

# 2. BIND MOUNTS (host filesystem, good for development)
docker run -v $(pwd)/src:/app/src nginx

# 3. TMPFS MOUNTS (in-memory only, never written to disk)
docker run --tmpfs /app/temp nginx
```

```
┌─────────────────────────────────────────────────┐
│                   HOST MACHINE                   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │              CONTAINER                    │   │
│  │                                           │   │
│  │  /app/data ──────┐                       │   │
│  │  /app/src  ──────┤                       │   │
│  │  /app/temp ──────┤                       │   │
│  └──────────────────┤───────────────────────┘   │
│                      │                           │
│         ┌────────────▼────────────┐              │
│         │    Volume: mydata       │◄── Docker    │
│         │    /var/lib/docker/     │    managed    │
│         │    volumes/mydata/_data │              │
│         ├─────────────────────────┤              │
│         │    Bind Mount           │◄── Direct    │
│         │    /home/user/project/  │    host path │
│         │    src                  │              │
│         ├─────────────────────────┤              │
│         │    tmpfs                │◄── RAM only  │
│         │    (in memory)          │              │
│         └─────────────────────────┘              │
└─────────────────────────────────────────────────┘
```

```bash
# Volume commands
docker volume ls
docker volume inspect mydata
docker volume rm mydata
docker volume prune          # Remove all unused volumes

# Named volumes with docker-compose (most common)
# Volumes persist even when containers are removed

# Backup a volume
docker run --rm -v mydata:/source -v $(pwd):/backup \
  alpine tar czf /backup/mydata-backup.tar.gz -C /source .

# Restore a volume
docker run --rm -v mydata:/target -v $(pwd):/backup \
  alpine tar xzf /backup/mydata-backup.tar.gz -C /target
```

---

## Container Networking

```
┌──────────────────────────────────────────────────────────┐
│                  DOCKER NETWORKING MODES                  │
│                                                           │
│  1. BRIDGE (default)                                      │
│  ┌─────────────────────────────────────┐                 │
│  │        docker0 bridge (172.17.0.1)  │                 │
│  │              │                      │                 │
│  │     ┌────────┼────────┐             │                 │
│  │     │        │        │             │                 │
│  │  ┌──▼──┐ ┌──▼──┐ ┌──▼──┐          │                 │
│  │  │.0.2 │ │.0.3 │ │.0.4 │          │                 │
│  │  │ C1  │ │ C2  │ │ C3  │          │                 │
│  │  └─────┘ └─────┘ └─────┘          │                 │
│  └─────────────────────────────────────┘                 │
│                                                           │
│  2. HOST - Container shares host's network stack          │
│  3. NONE - No networking                                  │
│  4. OVERLAY - Multi-host networking (Swarm/K8s)          │
│  5. MACVLAN - Container gets its own MAC address          │
└──────────────────────────────────────────────────────────┘
```

```bash
# Create custom bridge network
docker network create --driver bridge mynetwork

# Run containers on custom network (they can reach each other by NAME)
docker run -d --name api --network mynetwork myapi:latest
docker run -d --name db --network mynetwork postgres:15

# From 'api' container, you can now reach 'db' by hostname:
# postgres://db:5432/mydb   <-- 'db' resolves via Docker DNS

# Inspect network
docker network inspect mynetwork

# Port mapping
docker run -d -p 8080:3000 myapp    # host:container
docker run -d -p 127.0.0.1:8080:3000 myapp  # bind to localhost only

# List networks
docker network ls

# Connect running container to additional network
docker network connect mynetwork existing-container
```

---

## Resource Limits

```bash
# CPU limits
docker run -d \
  --cpus="1.5" \              # Use max 1.5 CPU cores
  --cpu-shares=512 \          # Relative CPU weight (default 1024)
  --cpuset-cpus="0,1" \       # Pin to specific CPUs
  myapp

# Memory limits
docker run -d \
  --memory="512m" \           # Hard memory limit
  --memory-swap="1g" \        # Memory + swap limit
  --memory-reservation="256m" \ # Soft limit
  --oom-kill-disable \        # Prevent OOM killer (use carefully!)
  myapp

# Combined resource limits
docker run -d \
  --name api \
  --cpus="2" \
  --memory="1g" \
  --memory-swap="2g" \
  --pids-limit=100 \          # Max number of processes
  --ulimit nofile=65535:65535 \ # File descriptor limits
  --restart=unless-stopped \
  myapp:latest

# Monitor resource usage
docker stats
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# In docker-compose.yml
services:
  api:
    image: myapp:latest
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
```

---

## Container Lifecycle

```
┌──────────────────────────────────────────────────────┐
│              CONTAINER LIFECYCLE                      │
│                                                       │
│  docker create                                        │
│       │                                               │
│       ▼                                               │
│  ┌─────────┐  docker start   ┌─────────┐            │
│  │ CREATED  │───────────────▶│ RUNNING  │            │
│  └─────────┘                 └────┬─────┘            │
│       ▲                           │                   │
│       │                    ┌──────┼──────┐            │
│       │                    │      │      │            │
│       │              docker│  docker│  docker│        │
│       │              pause │  stop  │  kill  │        │
│       │                    │      │      │            │
│       │                    ▼      ▼      ▼            │
│       │              ┌────────┐ ┌────────┐           │
│       │              │ PAUSED │ │STOPPED │           │
│       │              └───┬────┘ └───┬────┘           │
│       │                  │          │                 │
│       │           unpause│   start  │                 │
│       │                  │          │                 │
│       │                  ▼          ▼                 │
│       │              ┌─────────────────┐             │
│       │              │    RUNNING      │             │
│       │              └────────┬────────┘             │
│       │                       │                       │
│       │                docker rm                      │
│       │                       │                       │
│       │                       ▼                       │
│       │              ┌─────────────────┐             │
│       └──────────────│    DELETED      │             │
│                      └─────────────────┘             │
└──────────────────────────────────────────────────────┘
```

```bash
# Complete lifecycle commands
docker create --name myapp myimage:latest   # Created but not started
docker start myapp                          # Start the container
docker pause myapp                          # Freeze the container
docker unpause myapp                        # Resume
docker stop myapp                           # Graceful stop (SIGTERM, then SIGKILL after 10s)
docker kill myapp                           # Immediate stop (SIGKILL)
docker restart myapp                        # Stop + Start
docker rm myapp                             # Remove stopped container
docker rm -f myapp                          # Force remove running container

# Restart policies
docker run -d --restart=no myapp            # Never restart (default)
docker run -d --restart=always myapp        # Always restart
docker run -d --restart=unless-stopped myapp # Restart unless manually stopped
docker run -d --restart=on-failure:5 myapp  # Restart on failure, max 5 times

# Execute commands in running container
docker exec -it myapp /bin/sh
docker exec myapp cat /app/logs/app.log

# View logs
docker logs myapp
docker logs -f myapp                        # Follow
docker logs --tail 100 myapp                # Last 100 lines
docker logs --since 2h myapp                # Last 2 hours

# Copy files
docker cp myapp:/app/config.json ./config.json
docker cp ./newconfig.json myapp:/app/config.json

# Cleanup
docker system prune -a                     # Remove ALL unused data
docker container prune                      # Remove stopped containers
docker image prune -a                       # Remove unused images
```

---

## Docker Compose — Multi-Service Orchestration

### Production-Grade docker-compose.yml

```yaml
# docker-compose.yml
version: '3.9'

# =============================================
# SERVICES
# =============================================
services:

  # --- API Service ---
  api:
    build:
      context: ./api
      dockerfile: Dockerfile
      target: runner            # Multi-stage build target
      args:
        NODE_ENV: production
    image: myapp-api:latest
    container_name: myapp-api
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=myapp
      - REDIS_URL=redis://redis:6379
    env_file:
      - .env                   # Sensitive vars from file
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - backend
      - frontend
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    volumes:
      - api-logs:/app/logs

  # --- Worker Service ---
  worker:
    build:
      context: ./api
      dockerfile: Dockerfile
      target: runner
    container_name: myapp-worker
    restart: unless-stopped
    command: ["node", "dist/worker.js"]    # Override CMD
    environment:
      - NODE_ENV=production
      - REDIS_URL=redis://redis:6379
      - DB_HOST=postgres
    depends_on:
      - redis
      - postgres
    networks:
      - backend
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  # --- PostgreSQL ---
  postgres:
    image: postgres:15-alpine
    container_name: myapp-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d  # Init SQL scripts
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G

  # --- Redis ---
  redis:
    image: redis:7-alpine
    container_name: myapp-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # --- Nginx Reverse Proxy ---
  nginx:
    image: nginx:alpine
    container_name: myapp-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - api
    networks:
      - frontend

# =============================================
# NETWORKS
# =============================================
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true             # No external access to backend network

# =============================================
# VOLUMES
# =============================================
volumes:
  postgres-data:
    driver: local
  redis-data:
    driver: local
  api-logs:
    driver: local
```

### Docker Compose Commands

```bash
# Start all services
docker compose up -d

# Build and start
docker compose up -d --build

# Scale a service
docker compose up -d --scale worker=3

# View logs
docker compose logs -f api
docker compose logs -f --tail=50

# Stop all services
docker compose down

# Stop and remove volumes (CAUTION: destroys data!)
docker compose down -v

# Restart single service
docker compose restart api

# Execute command in service
docker compose exec api sh
docker compose exec postgres psql -U myuser -d myapp

# View service status
docker compose ps

# View resource usage
docker compose top
```

### Override Files for Environments

```yaml
# docker-compose.override.yml (automatically loaded in development)
version: '3.9'

services:
  api:
    build:
      target: deps                    # Use dev stage
    volumes:
      - ./api/src:/app/src           # Hot reload via bind mount
      - /app/node_modules            # Don't override node_modules
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    command: ["npx", "nodemon", "--watch", "src", "src/server.ts"]
    ports:
      - "9229:9229"                  # Debug port

  postgres:
    ports:
      - "5432:5432"                  # Expose for local tools
```

```bash
# Development (uses docker-compose.yml + docker-compose.override.yml)
docker compose up -d

# Production (explicit files)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Testing
docker compose -f docker-compose.yml -f docker-compose.test.yml run --rm test
```

---

# 2. DevOps & CI/CD

## CI/CD Concepts

```
┌──────────────────────────────────────────────────────────────┐
│                    CI/CD PIPELINE                             │
│                                                               │
│  CONTINUOUS INTEGRATION          CONTINUOUS DELIVERY/DEPLOY   │
│  ┌─────┐  ┌──────┐  ┌──────┐   ┌───────┐  ┌──────────────┐ │
│  │Code │─▶│Build │─▶│Test  │──▶│Stage  │─▶│  Production  │ │
│  │Push │  │      │  │      │   │Deploy │  │  Deploy      │ │
│  └─────┘  └──────┘  └──────┘   └───────┘  └──────────────┘ │
│     │         │         │           │             │          │
│     │    Compile    Unit Tests   Integration  Manual Gate    │
│     │    Lint       Coverage    E2E Tests    (Delivery)     │
│     │    SAST       Security                 or Automatic   │
│     │                                        (Deployment)   │
│                                                               │
│  CI = Build + Test automatically on every commit              │
│  CD (Delivery) = Deployable artifact ready, manual approval   │
│  CD (Deployment) = Automatic deployment to production         │
└──────────────────────────────────────────────────────────────┘
```

---

## GitHub Actions

### Complete CI/CD Pipeline

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  NODE_VERSION: '18'

# Cancel in-progress runs for same branch
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # ============================================
  # JOB 1: Lint & Type Check
  # ============================================
  lint:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Run TypeScript check
        run: npx tsc --noEmit

  # ============================================
  # JOB 2: Unit Tests
  # ============================================
  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        node-version: [18, 20]     # Test on multiple versions
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - run: npm ci
      - run: npm test -- --coverage

      - name: Upload coverage
        if: matrix.node-version == 18
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info

  # ============================================
  # JOB 3: Integration Tests
  # ============================================
  integration-test:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: lint

    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - run: npm ci
      - name: Run migrations
        run: npm run db:migrate
        env:
          DATABASE_URL: postgresql://testuser:testpass@localhost:5432/testdb

      - name: Run integration tests
        run: npm run test:integration
        env:
          DATABASE_URL: postgresql://testuser:testpass@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379

  # ============================================
  # JOB 4: Security Scanning
  # ============================================
  security:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4

      - name: Run Snyk security scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --severity-threshold=high

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH'

  # ============================================
  # JOB 5: Build & Push Docker Image
  # ============================================
  build:
    name: Build & Push Image
    runs-on: ubuntu-latest
    needs: [test, integration-test, security]
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write

    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=raw,value=latest,enable=${{ github.ref == 'refs/heads/main' }}

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          build-args: |
            NODE_ENV=production

  # ============================================
  # JOB 6: Deploy to Staging
  # ============================================
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    environment:
      name: staging
      url: https://staging.myapp.com

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster staging-cluster \
            --service api-service \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services api-service

      - name: Run smoke tests
        run: |
          curl -f https://staging.myapp.com/health || exit 1

  # ============================================
  # JOB 7: Deploy to Production
  # ============================================
  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment:
      name: production
      url: https://myapp.com
    # Manual approval required (configured in GitHub environment settings)

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to ECS (Blue/Green)
        run: |
          aws deploy create-deployment \
            --application-name myapp-prod \
            --deployment-group-name myapp-prod-dg \
            --revision revisionType=AppSpecContent,content='...'

      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Jenkins Pipeline

```groovy
// Jenkinsfile (Declarative Pipeline)
pipeline {
    agent any

    environment {
        REGISTRY = 'your-registry.com'
        IMAGE_NAME = 'myapp'
        DOCKER_CREDENTIALS = credentials('docker-registry-creds')
        AWS_CREDENTIALS = credentials('aws-creds')
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install & Lint') {
            steps {
                sh 'npm ci'
                sh 'npm run lint'
            }
        }

        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm run test:unit -- --coverage'
                    }
                    post {
                        always {
                            junit 'reports/junit.xml'
                            publishHTML(target: [
                                reportDir: 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh 'docker compose -f docker-compose.test.yml up -d'
                        sh 'npm run test:integration'
                    }
                    post {
                        always {
                            sh 'docker compose -f docker-compose.test.yml down -v'
                        }
                    }
                }
            }
        }

        stage('Security Scan') {
            steps {
                sh 'npm audit --audit-level=high'
                sh 'trivy fs --severity HIGH,CRITICAL .'
            }
        }

        stage('Build Docker Image') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def imageTag = "${REGISTRY}/${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker build -t ${imageTag} ."
                    sh "docker push ${imageTag}"
                    env.IMAGE_TAG = imageTag
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                sh """
                    aws ecs update-service \\
                        --cluster staging \\
                        --service api \\
                        --force-new-deployment
                """
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            input {
                message "Deploy to production?"
                ok "Yes, deploy!"
                submitter "lead-engineers"
            }
            steps {
                sh """
                    aws ecs update-service \\
                        --cluster production \\
                        --service api \\
                        --force-new-deployment
                """
            }
        }
    }

    post {
        success {
            slackSend(channel: '#deployments',
                      color: 'good',
                      message: "✅ Build ${env.BUILD_NUMBER} succeeded")
        }
        failure {
            slackSend(channel: '#deployments',
                      color: 'danger',
                      message: "❌ Build ${env.BUILD_NUMBER} failed")
        }
        always {
            cleanWs()
        }
    }
}
```

---

## GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - test
  - build
  - deploy-staging
  - deploy-production

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE
  NODE_VERSION: "18"

# Cache node_modules across jobs
cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/

# ============================================
# VALIDATE STAGE
# ============================================
lint:
  stage: validate
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci --cache .npm
    - npm run lint
    - npx tsc --noEmit
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/
      - node_modules/

# ============================================
# TEST STAGE
# ============================================
unit-tests:
  stage: test
  image: node:${NODE_VERSION}-alpine
  script:
    - npm ci
    - npm run test:unit -- --coverage
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      junit: reports/junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

integration-tests:
  stage: test
  image: node:${NODE_VERSION}
  services:
    - postgres:15-alpine
    - redis:7-alpine
  variables:
    POSTGRES_DB: testdb
    POSTGRES_USER: testuser
    POSTGRES_PASSWORD: testpass
    DATABASE_URL: postgresql://testuser:testpass@postgres:5432/testdb
    REDIS_URL: redis://redis:6379
  script:
    - npm ci
    - npm run db:migrate
    - npm run test:integration

# ============================================
# BUILD STAGE
# ============================================
build-image:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build
        --cache-from $DOCKER_IMAGE:latest
        --tag $DOCKER_IMAGE:$CI_COMMIT_SHA
        --tag $DOCKER_IMAGE:latest .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
    - docker push $DOCKER_IMAGE:latest
  only:
    - main

# ============================================
# DEPLOY STAGES
# ============================================
deploy-staging:
  stage: deploy-staging
  image: amazon/aws-cli:latest
  environment:
    name: staging
    url: https://staging.myapp.com
  script:
    - aws ecs update-service --cluster staging --service api --force-new-deployment
  only:
    - main

deploy-production:
  stage: deploy-production
  image: amazon/aws-cli:latest
  environment:
    name: production
    url: https://myapp.com
  script:
    - aws ecs update-service --cluster production --service api --force-new-deployment
  when: manual                 # Manual approval required
  only:
    - main
```

---

## Deployment Strategies

### Blue/Green Deployment

```
┌──────────────────────────────────────────────────────────┐
│                 BLUE/GREEN DEPLOYMENT                     │
│                                                           │
│  Step 1: Blue is live, Green is idle                      │
│  ┌──────────┐                                            │
│  │   Load   │──────▶ BLUE (v1.0) ✅ Live                │
│  │ Balancer │                                            │
│  └──────────┘        GREEN (idle)                        │
│                                                           │
│  Step 2: Deploy v2.0 to Green, test it                   │
│  ┌──────────┐                                            │
│  │   Load   │──────▶ BLUE (v1.0) ✅ Live                │
│  │ Balancer │                                            │
│  └──────────┘        GREEN (v2.0) 🧪 Testing            │
│                                                           │
│  Step 3: Switch traffic to Green                          │
│  ┌──────────┐                                            │
│  │   Load   │──────▶ GREEN (v2.0) ✅ Live               │
│  │ Balancer │                                            │
│  └──────────┘        BLUE (v1.0) 💤 Standby             │
│                                                           │
│  Rollback: Simply switch back to Blue                     │
│  Pros: Zero downtime, instant rollback                    │
│  Cons: Double infrastructure cost during deployment       │
└──────────────────────────────────────────────────────────┘
```

```yaml
# AWS CodeDeploy appspec.yml for Blue/Green
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "arn:aws:ecs:us-east-1:123456789:task-definition/myapp:2"
        LoadBalancerInfo:
          ContainerName: "myapp"
          ContainerPort: 3000
Hooks:
  - BeforeInstall: "scripts/before_install.sh"
  - AfterInstall: "scripts/after_install.sh"
  - AfterAllowTestTraffic: "scripts/run_tests.sh"
  - BeforeAllowTraffic: "scripts/validate.sh"
  - AfterAllowTraffic: "scripts/smoke_test.sh"
```

### Canary Deployment

```
┌──────────────────────────────────────────────────────────┐
│                  CANARY DEPLOYMENT                        │
│                                                           │
│  Step 1: 100% traffic to v1.0                            │
│  ┌──────────┐     ┌──────────────────────┐              │
│  │   Load   │────▶│  v1.0 (10 instances) │ 100%        │
│  │ Balancer │     └──────────────────────┘              │
│  └──────────┘                                            │
│                                                           │
│  Step 2: Route 5% traffic to v2.0 (canary)              │
│  ┌──────────┐     ┌──────────────────────┐              │
│  │   Load   │─95%▶│  v1.0 (10 instances) │              │
│  │ Balancer │     └──────────────────────┘              │
│  │          │─5%─▶│  v2.0 (1 instance)   │ ← Canary    │
│  └──────────┘     └──────────────────────┘              │
│                                                           │
│  Step 3: Monitor metrics. If healthy, increase           │
│  ┌──────────┐     ┌──────────────────────┐              │
│  │   Load   │─50%▶│  v1.0 (5 instances)  │              │
│  │ Balancer │     └──────────────────────┘              │
│  │          │─50%▶│  v2.0 (5 instances)  │              │
│  └──────────┘     └──────────────────────┘              │
│                                                           │
│  Step 4: Full rollout                                     │
│  ┌──────────┐     ┌──────────────────────┐              │
│  │   Load   │────▶│  v2.0 (10 instances) │ 100%        │
│  │ Balancer │     └──────────────────────┘              │
│  └──────────┘                                            │
│                                                           │
│  Auto-rollback if error rate > threshold                  │
└──────────────────────────────────────────────────────────┘
```

```yaml
# AWS ALB weighted target groups for canary
# Terraform example
resource "aws_lb_listener_rule" "canary" {
  listener_arn = aws_lb_listener.main.arn

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.stable.arn
        weight = 95
      }
      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = 5
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

### Feature Flags

```typescript
// Feature flag implementation
interface FeatureFlags {
  [key: string]: {
    enabled: boolean;
    percentage?: number;       // Percentage rollout
    allowedUsers?: string[];   // Specific user access
    metadata?: Record<string, any>;
  };
}

class FeatureFlagService {
  private flags: FeatureFlags;

  constructor(private flagProvider: FlagProvider) {}

  async initialize(): Promise<void> {
    // Load from remote config (LaunchDarkly, Unleash, AWS AppConfig)
    this.flags = await this.flagProvider.loadFlags();

    // Subscribe to real-time updates
    this.flagProvider.onUpdate((newFlags) => {
      this.flags = newFlags;
    });
  }

  isEnabled(flagName: string, context?: UserContext): boolean {
    const flag = this.flags[flagName];
    if (!flag) return false;
    if (!flag.enabled) return false;

    // Check user allowlist
    if (flag.allowedUsers && context?.userId) {
      if (flag.allowedUsers.includes(context.userId)) return true;
    }

    // Percentage-based rollout
    if (flag.percentage !== undefined && context?.userId) {
      const hash = this.hashUserId(context.userId);
      return hash % 100 < flag.percentage;
    }

    return flag.enabled;
  }

  private hashUserId(userId: string): number {
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      const char = userId.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return Math.abs(hash);
  }
}

// Usage in application code
class PaymentService {
  constructor(private featureFlags: FeatureFlagService) {}

  async processPayment(userId: string, amount: number) {
    if (this.featureFlags.isEnabled('new-payment-engine', { userId })) {
      // New payment processing logic
      return this.newPaymentEngine(amount);
    }

    // Existing payment logic
    return this.legacyPaymentEngine(amount);
  }
}

// Configuration example
const flags: FeatureFlags = {
  'new-payment-engine': {
    enabled: true,
    percentage: 10,            // 10% of users
    allowedUsers: ['internal-tester-1'],
  },
  'dark-mode': {
    enabled: true,
    percentage: 100,           // Everyone
  },
  'experimental-search': {
    enabled: true,
    percentage: 0,             // Nobody yet (kill switch ready)
    allowedUsers: ['qa-team-lead'],
  },
};
```

---

## Infrastructure as Code

### Terraform

```hcl
# main.tf - Complete AWS infrastructure

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state storage
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "myapp"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ============================================
# VARIABLES
# ============================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

# ============================================
# VPC
# ============================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "myapp-${var.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "production"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# ============================================
# ECS CLUSTER + SERVICE
# ============================================
resource "aws_ecs_cluster" "main" {
  name = "myapp-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "myapp-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "${aws_ecr_repository.api.repository_url}:latest"
      portMappings = [
        {
          containerPort = var.app_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "NODE_ENV", value = var.environment },
        { name = "PORT", value = tostring(var.app_port) },
      ]
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_secretsmanager_secret.db_url.arn
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "wget -q --spider http://localhost:${var.app_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.api.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = var.app_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
}

# ============================================
# ALB
# ============================================
resource "aws_lb" "main" {
  name               = "myapp-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "api" {
  name        = "myapp-api-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# ============================================
# AUTO SCALING
# ============================================
resource "aws_appautoscaling_target" "api" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ============================================
# RDS
# ============================================
resource "aws_db_instance" "main" {
  identifier     = "myapp-${var.environment}"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true

  db_name  = "myapp"
  username = "admin"
  password = random_password.db.result

  multi_az               = var.environment == "production"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 14
  deletion_protection     = var.environment == "production"

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
}

# ============================================
# OUTPUTS
# ============================================
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}
```

```bash
# Terraform workflow
terraform init              # Initialize, download providers
terraform fmt               # Format code
terraform validate          # Validate syntax
terraform plan              # Preview changes
terraform apply             # Apply changes
terraform destroy           # Tear down (careful!)

# State management
terraform state list        # List resources in state
terraform state show aws_ecs_service.api  # Show resource details
terraform import aws_s3_bucket.existing my-bucket  # Import existing resource
```

### CloudFormation

```yaml
# cloudformation-stack.yml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'MyApp Infrastructure'

Parameters:
  Environment:
    Type: String
    AllowedValues: [staging, production]
  AppImage:
    Type: String
    Description: Docker image URI

Resources:
  # ECS Cluster
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub 'myapp-${Environment}'
      ClusterSettings:
        - Name: containerInsights
          Value: enabled

  # Task Definition
  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: myapp-api
      Cpu: '512'
      Memory: '1024'
      NetworkMode: awsvpc
      RequiresCompatibilities: [FARGATE]
      ExecutionRoleArn: !GetAtt ExecutionRole.Arn
      TaskRoleArn: !GetAtt TaskRole.Arn
      ContainerDefinitions:
        - Name: api
          Image: !Ref AppImage
          PortMappings:
            - ContainerPort: 3000
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref LogGroup
              awslogs-region: !Ref AWS::Region
              awslogs-stream-prefix: api
          Environment:
            - Name: NODE_ENV
              Value: !Ref Environment

  # ECS Service
  ECSService:
    Type: AWS::ECS::Service
    DependsOn: ALBListener
    Properties:
      Cluster: !Ref ECSCluster
      DesiredCount: 3
      LaunchType: FARGATE
      TaskDefinition: !Ref TaskDefinition
      NetworkConfiguration:
        AwsvpcConfiguration:
          Subnets:
            - !Ref PrivateSubnet1
            - !Ref PrivateSubnet2
          SecurityGroups:
            - !Ref ServiceSecurityGroup
      LoadBalancers:
        - ContainerName: api
          ContainerPort: 3000
          TargetGroupArn: !Ref TargetGroup

Outputs:
  ServiceURL:
    Value: !Sub 'https://${ALB.DNSName}'
```

---

# 3. CLOUD (AWS)

## AWS Core Services

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS SERVICES MAP                         │
│                                                              │
│  COMPUTE          STORAGE          NETWORKING                │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │   EC2    │    │    S3    │    │   VPC    │              │
│  │  (VMs)   │    │ (Object) │    │(Network) │              │
│  ├──────────┤    ├──────────┤    ├──────────┤              │
│  │  Lambda  │    │   EBS    │    │Route 53  │              │
│  │(Srvless) │    │ (Block)  │    │  (DNS)   │              │
│  ├──────────┤    ├──────────┤    ├──────────┤              │
│  │   ECS    │    │   EFS    │    │CloudFront│              │
│  │(Contanrs)│    │ (File)   │    │  (CDN)   │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│                                                              │
│  DATABASE         SECURITY         MESSAGING                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │   RDS    │    │   IAM    │    │   SQS    │              │
│  │(Relation)│    │(Identity)│    │ (Queue)  │              │
│  ├──────────┤    ├──────────┤    ├──────────┤              │
│  │ DynamoDB │    │   KMS    │    │   SNS    │              │
│  │(NoSQL)   │    │  (Keys)  │    │(Pub/Sub) │              │
│  ├──────────┤    ├──────────┤    ├──────────┤              │
│  │ElastiCach│    │ Secrets  │    │EventBridg│              │
│  │(Cache)   │    │ Manager  │    │(Events)  │              │
│  └──────────┘    └──────────┘    └──────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### EC2 (Elastic Compute Cloud)

```bash
# EC2 Instance Types
# General Purpose:   t3, m6i    (balanced CPU/memory)
# Compute Optimized: c6i, c7g   (high CPU for computation)
# Memory Optimized:  r6i, x2idn (in-memory databases)
# Storage Optimized: i3, d3     (high sequential I/O)
# Accelerated:       p4d, g5    (GPU for ML/rendering)

# Launch an EC2 instance with AWS CLI
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.medium \
  --key-name my-key-pair \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --iam-instance-profile Name=MyInstanceProfile \
  --user-data file://startup-script.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyServer}]' \
  --block-device-mappings '[{
    "DeviceName":"/dev/xvda",
    "Ebs":{"VolumeSize":50,"VolumeType":"gp3","Encrypted":true}
  }]'
```

```bash
#!/bin/bash
# startup-script.sh (EC2 User Data)
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

# Pull and run application
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

docker pull 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker run -d -p 80:3000 --restart always \
  --name myapp \
  123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

### S3 (Simple Storage Service)

```python
import boto3
from botocore.config import Config

# Initialize S3 client
s3 = boto3.client('s3', config=Config(
    retries={'max_attempts': 3, 'mode': 'adaptive'},
    signature_version='s3v4'
))

# ============================================
# Upload with server-side encryption
# ============================================
def upload_file(bucket: str, key: str, file_path: str):
    s3.upload_file(
        file_path, bucket, key,
        ExtraArgs={
            'ServerSideEncryption': 'aws:kms',
            'ContentType': 'application/json',
            'Metadata': {'uploaded-by': 'api-service'}
        }
    )

# ============================================
# Generate presigned URL (for secure direct uploads)
# ============================================
def generate_presigned_upload_url(bucket: str, key: str, expires_in: int = 3600):
    url = s3.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': bucket,
            'Key': key,
            'ContentType': 'image/jpeg',
        },
        ExpiresIn=expires_in
    )
    return url

# ============================================
# List objects with pagination
# ============================================
def list_all_objects(bucket: str, prefix: str):
    paginator = s3.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)

    for page in pages:
        for obj in page.get('Contents', []):
            yield obj['Key'], obj['Size']

# ============================================
# S3 Event Notification -> Lambda
# ============================================
# When a file is uploaded to S3, trigger Lambda for processing
# Configured via Terraform or console
```

```hcl
# S3 bucket with best practices (Terraform)
resource "aws_s3_bucket" "data" {
  bucket = "myapp-data-${var.environment}"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "archive-old-data"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "STANDARD_IA"  # Infrequent Access
    }
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
    expiration {
      days = 2555  # ~7 years
    }
  }
}
```

### VPC (Virtual Private Cloud)

```
┌───────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                     │
│                                                                │
│  ┌──────────────────────────── AZ-a ────────────────────────┐ │
│  │  ┌─────────────────────┐  ┌─────────────────────┐       │ │
│  │  │  Public Subnet      │  │  Private Subnet      │      │ │
│  │  │  10.0.1.0/24        │  │  10.0.11.0/24        │      │ │
│  │  │                     │  │                       │      │ │
│  │  │  ┌──────────┐       │  │  ┌──────────┐        │      │ │
│  │  │  │   ALB    │       │  │  │  ECS     │        │      │ │
│  │  │  │          │       │  │  │  Tasks   │        │      │ │
│  │  │  └──────────┘       │  │  └──────────┘        │      │ │
│  │  │  ┌──────────┐       │  │  ┌──────────┐        │      │ │
│  │  │  │   NAT    │       │  │  │   RDS    │        │      │ │
│  │  │  │ Gateway  │       │  │  │(Primary) │        │      │ │
│  │  │  └──────────┘       │  │  └──────────┘        │      │ │
│  │  └─────────────────────┘  └─────────────────────┘       │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────── AZ-b ────────────────────────┐ │
│  │  ┌─────────────────────┐  ┌─────────────────────┐       │ │
│  │  │  Public Subnet      │  │  Private Subnet      │      │ │
│  │  │  10.0.2.0/24        │  │  10.0.12.0/24        │      │ │
│  │  │                     │  │                       │      │ │
│  │  │  ┌──────────┐       │  │  ┌──────────┐        │      │ │
│  │  │  │   ALB    │       │  │  │  ECS     │        │      │ │
│  │  │  │  (node)  │       │  │  │  Tasks   │        │      │ │
│  │  │  └──────────┘       │  │  └──────────┘        │      │ │
│  │  │                     │  │  ┌──────────┐        │      │ │
│  │  │                     │  │  │   RDS    │        │      │ │
│  │  │                     │  │  │(Standby) │        │      │ │
│  │  └─────────────────────┘  └─────────────────────┘       │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐      │
│  │  Internet Gateway (IGW) - connects VPC to internet  │      │
│  └─────────────────────────────────────────────────────┘      │
│                                                                │
│  Route Tables:                                                 │
│  Public:  0.0.0.0/0 → IGW (internet access)                  │
│  Private: 0.0.0.0/0 → NAT Gateway (outbound only)            │
└───────────────────────────────────────────────────────────────┘
```

### IAM (Identity and Access Management)

```json
// Least-privilege IAM policy for ECS task
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3Access",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::myapp-uploads",
        "arn:aws:s3:::myapp-uploads/*"
      ]
    },
    {
      "Sid": "AllowSQSAccess",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:us-east-1:123456789:myapp-queue"
    },
    {
      "Sid": "AllowSecretsManager",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789:secret:myapp/*"
    },
    {
      "Sid": "DenyAll",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

```
IAM Concepts:
┌─────────────────────────────────────────────────┐
│  Users     → Human identities                    │
│  Groups    → Collection of users                 │
│  Roles     → Assumed by services/applications    │
│  Policies  → JSON documents defining permissions │
│                                                   │
│  Best Practices:                                  │
│  • Never use root account                        │
│  • Enable MFA everywhere                         │
│  • Use roles for applications (not access keys)  │
│  • Apply least privilege principle               │
│  • Use IAM Access Analyzer                       │
│  • Rotate credentials regularly                  │
│  • Use Service Control Policies (SCPs) in Orgs   │
└─────────────────────────────────────────────────┘
```

---

## Serverless

### Lambda

```python
# lambda_function.py - Complete Lambda handler
import json
import os
import logging
import boto3
from typing import Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize clients OUTSIDE handler (reused across invocations)
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])
s3 = boto3.client('s3')

def handler(event: dict, context: Any) -> dict:
    """
    Lambda handler for API Gateway proxy integration.

    context attributes:
      - function_name: Name of the Lambda function
      - memory_limit_in_mb: Memory allocated
      - aws_request_id: Unique request ID
      - get_remaining_time_in_millis(): Time left before timeout
    """
    logger.info(f"Event: {json.dumps(event)}")
    logger.info(f"Remaining time: {context.get_remaining_time_in_millis()}ms")

    try:
        http_method = event['httpMethod']
        path = event['path']

        if http_method == 'GET' and path == '/users':
            return get_users(event)
        elif http_method == 'POST' and path == '/users':
            return create_user(event)
        elif http_method == 'GET' and path.startswith('/users/'):
            user_id = event['pathParameters']['id']
            return get_user(user_id)
        else:
            return response(404, {'error': 'Not Found'})

    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return response(500, {'error': 'Internal Server Error'})


def get_users(event: dict) -> dict:
    # Query with pagination
    query_params = event.get('queryStringParameters') or {}
    limit = int(query_params.get('limit', 20))

    scan_kwargs = {'Limit': limit}
    if 'cursor' in query_params:
        scan_kwargs['ExclusiveStartKey'] = {'id': query_params['cursor']}

    result = table.scan(**scan_kwargs)

    return response(200, {
        'users': result['Items'],
        'cursor': result.get('LastEvaluatedKey', {}).get('id')
    })


def create_user(event: dict) -> dict:
    body = json.loads(event['body'])

    import uuid
    user = {
        'id': str(uuid.uuid4()),
        'name': body['name'],
        'email': body['email'],
        'created_at': int(time.time())
    }

    table.put_item(Item=user)
    return response(201, user)


def get_user(user_id: str) -> dict:
    result = table.get_item(Key={'id': user_id})
    item = result.get('Item')

    if not item:
        return response(404, {'error': 'User not found'})
    return response(200, item)


def response(status_code: int, body: dict) -> dict:
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'X-Request-Id': '',  # Set by API Gateway
        },
        'body': json.dumps(body, default=str)
    }
```

### Lambda with SQS (Event-Driven)

```python
# sqs_processor.py
import json
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Process SQS messages in batches.
    Lambda automatically deletes successfully processed messages.
    Failed messages return to queue or go to DLQ.
    """
    failed_records = []

    for record in event['Records']:
        try:
            message = json.loads(record['body'])
            process_order(message)
            logger.info(f"Processed message: {record['messageId']}")

        except Exception as e:
            logger.error(f"Failed to process {record['messageId']}: {e}")
            # Report individual failures (partial batch failure)
            failed_records.append({
                'itemIdentifier': record['messageId']
            })

    # Return failed records so only they go back to queue
    return {
        'batchItemFailures': failed_records
    }


def process_order(message: dict):
    order_id = message['order_id']
    # Process the order...
    logger.info(f"Processing order {order_id}")
```

### API Gateway + Lambda (Terraform)

```hcl
# API Gateway v2 (HTTP API) + Lambda
resource "aws_apigatewayv2_api" "main" {
  name          = "myapp-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["Content-Type", "Authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_origins = ["https://myapp.com"]
    max_age       = 86400
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "prod"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.integrationLatency"
    })
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api_gw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
```

### Step Functions

```json
{
  "Comment": "Order Processing Workflow",
  "StartAt": "ValidateOrder",
  "States": {
    "ValidateOrder": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789:function:validateOrder",
      "Next": "CheckInventory",
      "Catch": [{
        "ErrorEquals": ["ValidationError"],
        "Next": "OrderFailed"
      }],
      "Retry": [{
        "ErrorEquals": ["States.TaskFailed"],
        "IntervalSeconds": 2,
        "MaxAttempts": 3,
        "BackoffRate": 2
      }]
    },
    "CheckInventory": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789:function:checkInventory",
      "Next": "InventoryDecision"
    },
    "InventoryDecision": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.inStock",
          "BooleanEquals": true,
          "Next": "ProcessPayment"
        }
      ],
      "Default": "WaitForRestock"
    },
    "WaitForRestock": {
      "Type": "Wait",
      "Seconds": 3600,
      "Next": "CheckInventory"
    },
    "ProcessPayment": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:123456789:function:processPayment",
      "Next": "ParallelFulfillment"
    },
    "ParallelFulfillment": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "ShipOrder",
          "States": {
            "ShipOrder": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:us-east-1:123456789:function:shipOrder",
              "End": true
            }
          }
        },
        {
          "StartAt": "SendConfirmation",
          "States": {
            "SendConfirmation": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:us-east-1:123456789:function:sendEmail",
              "End": true
            }
          }
        }
      ],
      "Next": "OrderComplete"
    },
    "OrderComplete": {
      "Type": "Succeed"
    },
    "OrderFailed": {
      "Type": "Fail",
      "Error": "OrderProcessingError",
      "Cause": "Order validation failed"
    }
  }
}
```

```
Step Functions Visualization:
┌──────────────┐
│ValidateOrder │
└──────┬───────┘
       │
┌──────▼───────┐
│CheckInventory│◄────────────────┐
└──────┬───────┘                 │
       │                         │
┌──────▼──────────┐    ┌────────┴───────┐
│InventoryDecision│───▶│WaitForRestock  │
│  (inStock?)     │ No │ (1 hour wait)  │
└──────┬──────────┘    └────────────────┘
       │ Yes
┌──────▼───────┐
│ProcessPayment│
└──────┬───────┘
       │
┌──────▼──────────────────┐
│   ParallelFulfillment   │
│  ┌──────┐  ┌──────────┐│
│  │Ship  │  │Send Email ││
│  │Order │  │Confirm   ││
│  └──────┘  └──────────┘│
└──────────┬──────────────┘
           │
┌──────────▼──┐
│OrderComplete│
└─────────────┘
```

---

## AWS Data Services

### RDS (Relational Database Service)

```hcl
# Production RDS with read replicas
resource "aws_db_instance" "primary" {
  identifier     = "myapp-prod-primary"
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.xlarge"

  # Storage
  allocated_storage     = 200
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  # Database
  db_name  = "myapp"
  username = "admin"
  password = aws_secretsmanager_secret_version.db_password.secret_string

  # High Availability
  multi_az = true

  # Networking
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = 14
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Monitoring
  performance_insights_enabled    = true
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "myapp-prod-final-snapshot"

  # Parameter Group
  parameter_group_name = aws_db_parameter_group.custom.name
}

# Read Replica (for read-heavy workloads)
resource "aws_db_instance" "read_replica" {
  identifier          = "myapp-prod-read-1"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = "db.r6g.large"
  publicly_accessible = false

  # Read replicas can have their own backup settings
  backup_retention_period = 0  # No backups needed for replica
}

# Custom parameter group for tuning
resource "aws_db_parameter_group" "custom" {
  name   = "myapp-postgres15"
  family = "postgres15"

  parameter {
    name  = "max_connections"
    value = "500"
  }
  parameter {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries > 1 second
  }
}
```

### DynamoDB

```python
import boto3
from boto3.dynamodb.conditions import Key, Attr
import time

dynamodb = boto3.resource('dynamodb')

# ============================================
# Table Design - Single Table Design
# ============================================
"""
Table: MyApp
Partition Key: PK (String)
Sort Key: SK (String)
GSI1: GSI1PK, GSI1SK

Access Patterns:
1. Get user by ID           → PK=USER#123, SK=PROFILE
2. Get user's orders        → PK=USER#123, SK=begins_with(ORDER#)
3. Get order by ID          → PK=ORDER#456, SK=ORDER#456
4. Get orders by date (GSI) → GSI1PK=USER#123, GSI1SK=2024-01-15
"""

table = dynamodb.Table('MyApp')

# ============================================
# Write Operations
# ============================================

# Put item (create or replace)
def create_user(user_id: str, name: str, email: str):
    table.put_item(
        Item={
            'PK': f'USER#{user_id}',
            'SK': 'PROFILE',
            'GSI1PK': f'EMAIL#{email}',
            'GSI1SK': f'USER#{user_id}',
            'name': name,
            'email': email,
            'created_at': int(time.time()),
        },
        ConditionExpression='attribute_not_exists(PK)',  # Prevent overwrite
    )

# Update with conditional expression
def update_user_email(user_id: str, old_email: str, new_email: str):
    table.update_item(
        Key={'PK': f'USER#{user_id}', 'SK': 'PROFILE'},
        UpdateExpression='SET email = :new_email, GSI1PK = :new_gsi',
        ConditionExpression='email = :old_email',  # Optimistic locking
        ExpressionAttributeValues={
            ':new_email': new_email,
            ':old_email': old_email,
            ':new_gsi': f'EMAIL#{new_email}',
        },
    )

# Transactional write (all-or-nothing)
def create_order(user_id: str, order_id: str, items: list, total: float):
    client = boto3.client('dynamodb')
    client.transact_write_items(
        TransactItems=[
            {
                'Put': {
                    'TableName': 'MyApp',
                    'Item': {
                        'PK': {'S': f'ORDER#{order_id}'},
                        'SK': {'S': f'ORDER#{order_id}'},
                        'GSI1PK': {'S': f'USER#{user_id}'},
                        'GSI1SK': {'S': f'2024-01-15T10:30:00Z'},
                        'total': {'N': str(total)},
                        'status': {'S': 'PENDING'},
                    },
                }
            },
            {
                'Update': {
                    'TableName': 'MyApp',
                    'Key': {
                        'PK': {'S': f'USER#{user_id}'},
                        'SK': {'S': 'PROFILE'},
                    },
                    'UpdateExpression': 'ADD order_count :inc',
                    'ExpressionAttributeValues': {
                        ':inc': {'N': '1'},
                    },
                }
            },
        ]
    )

# ============================================
# Read Operations
# ============================================

# Get single item
def get_user(user_id: str):
    response = table.get_item(
        Key={'PK': f'USER#{user_id}', 'SK': 'PROFILE'},
        ConsistentRead=True,  # Strongly consistent (costs 2x RCU)
    )
    return response.get('Item')

# Query user's orders (sorted by SK)
def get_user_orders(user_id: str, limit: int = 20, cursor: str = None):
    kwargs = {
        'KeyConditionExpression': Key('PK').eq(f'USER#{user_id}') & Key('SK').begins_with('ORDER#'),
        'Limit': limit,
        'ScanIndexForward': False,  # Newest first
    }
    if cursor:
        kwargs['ExclusiveStartKey'] = {'PK': f'USER#{user_id}', 'SK': cursor}

    response = table.query(**kwargs)
    return {
        'items': response['Items'],
        'cursor': response.get('LastEvaluatedKey', {}).get('SK'),
    }

# Query GSI
def get_orders_by_date(user_id: str, start_date: str, end_date: str):
    response = table.query(
        IndexName='GSI1',
        KeyConditionExpression=(
            Key('GSI1PK').eq(f'USER#{user_id}') &
            Key('GSI1SK').between(start_date, end_date)
        ),
    )
    return response['Items']

# Batch get (up to 100 items)
def batch_get_users(user_ids: list):
    keys = [{'PK': f'USER#{uid}', 'SK': 'PROFILE'} for uid in user_ids]

    response = dynamodb.batch_get_item(
        RequestItems={'MyApp': {'Keys': keys}}
    )
    return response['Responses']['MyApp']
```

---

## Auto Scaling & Load Balancing

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTO SCALING + ALB                         │
│                                                              │
│  Internet                                                    │
│     │                                                        │
│     ▼                                                        │
│  ┌─────────────────────────────────────┐                    │
│  │     Application Load Balancer       │                    │
│  │  ┌────────────────────────────────┐ │                    │
│  │  │ Listener :443 (HTTPS)          │ │                    │
│  │  │  ├─ /api/*  → API Target Group │ │                    │
│  │  │  ├─ /ws/*   → WS Target Group  │ │                    │
│  │  │  └─ /*      → Web Target Group │ │                    │
│  │  └────────────────────────────────┘ │                    │
│  └──────────────┬──────────────────────┘                    │
│                 │                                            │
│     ┌───────────┼───────────┐                               │
│     ▼           ▼           ▼                               │
│  ┌──────┐  ┌──────┐  ┌──────┐                              │
│  │ i-1  │  │ i-2  │  │ i-3  │  ← Auto Scaling Group       │
│  │(AZ-a)│  │(AZ-b)│  │(AZ-c)│    Min: 2, Max: 10          │
│  └──────┘  └──────┘  └──────┘    Desired: 3                │
│                                                              │
│  Scaling Policies:                                           │
│  • Target Tracking: CPU avg < 70%                           │
│  • Step Scaling: Add 2 if CPU > 90% for 5 min              │
│  • Scheduled: Scale to 6 at 9am, back to 3 at 6pm          │
│  • Predictive: ML-based (learns traffic patterns)           │
└─────────────────────────────────────────────────────────────┘
```

```hcl
# Auto Scaling Group
resource "aws_autoscaling_group" "api" {
  name                = "api-asg"
  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns   = [aws_lb_target_group.api.arn]

  min_size         = 2
  max_size         = 10
  desired_capacity = 3

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 75
      instance_warmup        = 120
    }
  }

  tag {
    key                 = "Name"
    value               = "api-instance"
    propagate_at_launch = true
  }
}

# Target Tracking Policy
resource "aws_autoscaling_policy" "cpu" {
  name                   = "cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.api.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Custom metric scaling (e.g., request count per target)
resource "aws_autoscaling_policy" "request_count" {
  name                   = "request-count-tracking"
  autoscaling_group_name = aws_autoscaling_group.api.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label        = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.api.arn_suffix}"
    }
    target_value = 1000.0   # 1000 requests per target
  }
}

# Scheduled scaling
resource "aws_autoscaling_schedule" "morning_scale_up" {
  scheduled_action_name  = "morning-scale-up"
  autoscaling_group_name = aws_autoscaling_group.api.name
  min_size               = 4
  max_size               = 10
  desired_capacity       = 6
  recurrence             = "0 9 * * MON-FRI"  # 9am weekdays
}

resource "aws_autoscaling_schedule" "evening_scale_down" {
  scheduled_action_name  = "evening-scale-down"
  autoscaling_group_name = aws_autoscaling_group.api.name
  min_size               = 2
  max_size               = 10
  desired_capacity       = 3
  recurrence             = "0 18 * * MON-FRI"  # 6pm weekdays
}
```

---

# 4. OBSERVABILITY & PRODUCTION RELIABILITY

## The Three Pillars of Observability

```
┌──────────────────────────────────────────────────────────┐
│              THREE PILLARS OF OBSERVABILITY               │
│                                                           │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────┐   │
│  │   LOGS     │  │  METRICS   │  │  TRACES          │   │
│  │            │  │            │  │                    │   │
│  │ What       │  │ What       │  │ What              │   │
│  │ happened?  │  │ is the     │  │ is the request    │   │
│  │            │  │ state?     │  │ flow?             │   │
│  │            │  │            │  │                    │   │
│  │ Examples:  │  │ Examples:  │  │ Examples:          │   │
│  │ • Errors   │  │ • CPU %    │  │ • Request path    │   │
│  │ • Requests │  │ • Latency  │  │   across services │   │
│  │ • Events   │  │ • QPS      │  │ • Bottleneck      │   │
│  │            │  │ • Errors/s │  │   identification  │   │
│  │            │  │            │  │                    │   │
│  │ Tools:     │  │ Tools:     │  │ Tools:            │   │
│  │ • ELK      │  │ • Prometh. │  │ • Jaeger          │   │
│  │ • CloudW.  │  │ • Grafana  │  │ • Zipkin          │   │
│  │ • Datadog  │  │ • Datadog  │  │ • AWS X-Ray       │   │
│  └────────────┘  └────────────┘  └──────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## Structured Logging

```typescript
// Structured logging with Winston (Node.js)
import winston from 'winston';

// Custom log format with correlation ID
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'api-service',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV,
  },
  transports: [
    new winston.transports.Console(),
    // In production, ship to CloudWatch/ELK/Datadog
  ],
});

// Middleware to add request context
import { v4 as uuidv4 } from 'uuid';
import { Request, Response, NextFunction } from 'express';

interface RequestWithLogger extends Request {
  logger: winston.Logger;
  requestId: string;
}

function requestLoggerMiddleware(req: RequestWithLogger, res: Response, next: NextFunction) {
  const requestId = req.headers['x-request-id'] as string || uuidv4();
  const startTime = Date.now();

  // Create child logger with request context
  req.requestId = requestId;
  req.logger = logger.child({
    requestId,
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent'),
    userId: (req as any).user?.id,
  });

  // Set response header for tracing
  res.setHeader('X-Request-Id', requestId);

  // Log request start
  req.logger.info('Request started');

  // Log request completion
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const logLevel = res.statusCode >= 500 ? 'error'
                   : res.statusCode >= 400 ? 'warn'
                   : 'info';

    req.logger.log(logLevel, 'Request completed', {
      statusCode: res.statusCode,
      duration,
      contentLength: res.get('content-length'),
    });
  });

  next();
}

// Usage in route handlers
app.get('/api/users/:id', async (req: RequestWithLogger, res) => {
  req.logger.info('Fetching user', { userId: req.params.id });

  try {
    const user = await userService.findById(req.params.id);

    if (!user) {
      req.logger.warn('User not found', { userId: req.params.id });
      return res.status(404).json({ error: 'User not found' });
    }

    req.logger.info('User found', {
      userId: user.id,
      // DON'T log PII (email, name, etc.)
    });

    res.json(user);
  } catch (error) {
    req.logger.error('Failed to fetch user', {
      userId: req.params.id,
      error: error.message,
      stack: error.stack,
    });
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**Example Log Output:**
```json
{
  "level": "info",
  "message": "Request completed",
  "timestamp": "2024-01-15T10:30:45.123Z",
  "service": "api-service",
  "version": "2.1.0",
  "environment": "production",
  "requestId": "abc-123-def-456",
  "method": "GET",
  "path": "/api/users/789",
  "ip": "10.0.1.50",
  "userId": "user-001",
  "statusCode": 200,
  "duration": 45,
  "contentLength": "1234"
}
```

---

## Metrics with Prometheus

```typescript
// metrics.ts - Prometheus metrics for Node.js
import promClient from 'prom-client';

// Enable default metrics (CPU, memory, event loop, etc.)
promClient.collectDefaultMetrics({
  prefix: 'myapp_',
  gcDurationBuckets: [0.001, 0.01, 0.1, 1, 2, 5],
});

// ============================================
// Custom Metrics
// ============================================

// Counter - only goes up (requests, errors)
const httpRequestsTotal = new promClient.Counter({
  name: 'myapp_http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status_code'],
});

// Histogram - measures distribution (latency)
const httpRequestDuration = new promClient.Histogram({
  name: 'myapp_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'path', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
});

// Gauge - goes up and down (active connections, queue size)
const activeConnections = new promClient.Gauge({
  name: 'myapp_active_connections',
  help: 'Number of active connections',
});

const queueSize = new promClient.Gauge({
  name: 'myapp_queue_size',
  help: 'Current size of the job queue',
  labelNames: ['queue_name'],
});

// Summary - similar to histogram but calculates percentiles client-side
const dbQueryDuration = new promClient.Summary({
  name: 'myapp_db_query_duration_seconds',
  help: 'Database query duration',
  labelNames: ['query_type', 'table'],
  percentiles: [0.5, 0.9, 0.95, 0.99],
});

// ============================================
// Middleware to record metrics
// ============================================
function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();
  activeConnections.inc();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const labels = {
      method: req.method,
      path: req.route?.path || req.path,  // Use route pattern, not actual path
      status_code: res.statusCode.toString(),
    };

    httpRequestsTotal.inc(labels);
    httpRequestDuration.observe(labels, duration);
    activeConnections.dec();
  });

  next();
}

// ============================================
// Metrics endpoint
// ============================================
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});

// ============================================
// Business metrics example
// ============================================
const ordersCreated = new promClient.Counter({
  name: 'myapp_orders_created_total',
  help: 'Total orders created',
  labelNames: ['payment_method', 'region'],
});

const orderValue = new promClient.Histogram({
  name: 'myapp_order_value_dollars',
  help: 'Order value distribution',
  buckets: [10, 25, 50, 100, 250, 500, 1000, 5000],
});

async function createOrder(order: Order) {
  // ... business logic ...
  ordersCreated.inc({
    payment_method: order.paymentMethod,
    region: order.region,
  });
  orderValue.observe(order.total);
}
```

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - 'alert_rules.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'api-service'
    metrics_path: '/metrics'
    dns_sd_configs:
      - names: ['api.service.consul']
        type: 'SRV'
    # Or static targets
    static_configs:
      - targets: ['api:3000']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
```

### Alert Rules

```yaml
# alert_rules.yml
groups:
  - name: api-alerts
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          sum(rate(myapp_http_requests_total{status_code=~"5.."}[5m]))
          /
          sum(rate(myapp_http_requests_total[5m]))
          > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate ({{ $value | humanizePercentage }})"
          description: "More than 5% of requests are failing"

      # High latency
      - alert: HighLatencyP99
        expr: |
          histogram_quantile(0.99,
            sum(rate(myapp_http_request_duration_seconds_bucket[5m])) by (le)
          ) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency is {{ $value }}s"
          description: "99th percentile latency exceeds 2 seconds"

      # Service down
      - alert: ServiceDown
        expr: up{job="api-service"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "API service is down"

      # High memory usage
      - alert: HighMemoryUsage
        expr: |
          process_resident_memory_bytes{job="api-service"}
          /
          1024 / 1024 / 1024
          > 1.5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Memory usage is {{ $value }}GB"

      # Queue backing up
      - alert: QueueBacklog
        expr: myapp_queue_size{queue_name="orders"} > 1000
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Order queue has {{ $value }} messages"

      # Database connection pool exhaustion
      - alert: DBConnectionPoolNearExhaustion
        expr: |
          myapp_db_pool_active_connections
          /
          myapp_db_pool_max_connections
          > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "DB connection pool is {{ $value | humanizePercentage }} utilized"
```

---

## Grafana Dashboards

```json
// Grafana dashboard JSON (key panels)
{
  "panels": [
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [
        {
          "expr": "sum(rate(myapp_http_requests_total[5m])) by (status_code)",
          "legendFormat": "{{status_code}}"
        }
      ]
    },
    {
      "title": "Latency Percentiles",
      "type": "timeseries",
      "targets": [
        {
          "expr": "histogram_quantile(0.50, sum(rate(myapp_http_request_duration_seconds_bucket[5m])) by (le))",
          "legendFormat": "p50"
        },
        {
          "expr": "histogram_quantile(0.95, sum(rate(myapp_http_request_duration_seconds_bucket[5m])) by (le))",
          "legendFormat": "p95"
        },
        {
          "expr": "histogram_quantile(0.99, sum(rate(myapp_http_request_duration_seconds_bucket[5m])) by (le))",
          "legendFormat": "p99"
        }
      ]
    },
    {
      "title": "Error Rate (%)",
      "type": "stat",
      "targets": [
        {
          "expr": "sum(rate(myapp_http_requests_total{status_code=~\"5..\"}[5m])) / sum(rate(myapp_http_requests_total[5m])) * 100"
        }
      ],
      "thresholds": {
        "steps": [
          {"color": "green", "value": 0},
          {"color": "yellow", "value": 1},
          {"color": "red", "value": 5}
        ]
      }
    }
  ]
}
```

### RED Method Dashboard

```
┌───────────────────────────────────────────────────────┐
│                RED METHOD                              │
│  (For request-driven services)                         │
│                                                        │
│  R - Rate:      Requests per second                   │
│  E - Errors:    Failed requests per second            │
│  D - Duration:  Latency distribution                  │
│                                                        │
│  ┌─────────────────────────────────────────────┐      │
│  │ Request Rate          Error Rate             │      │
│  │ ▁▃▅▇█▇▅▃▁            ▁▁▁▁▁▁▃▇▃▁            │      │
│  │ 250 req/s             0.5%                   │      │
│  ├─────────────────────────────────────────────┤      │
│  │ P50 Latency    P95 Latency    P99 Latency  │      │
│  │ ▁▂▃▃▃▃▂▁      ▁▂▃▅▅▃▂▁      ▁▃▅▇▇▅▃▁     │      │
│  │ 15ms           85ms           250ms         │      │
│  └─────────────────────────────────────────────┘      │
│                                                        │
│                USE METHOD                              │
│  (For resources: CPU, memory, disk, network)          │
│                                                        │
│  U - Utilization: % of capacity used                  │
│  S - Saturation:  Queue depth / backlog               │
│  E - Errors:      Error count                         │
└───────────────────────────────────────────────────────┘
```

---

## Distributed Tracing

```typescript
// OpenTelemetry setup for distributed tracing
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { trace, SpanStatusCode, context, propagation } from '@opentelemetry/api';

// Initialize SDK (do this BEFORE importing other modules)
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'api-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '2.1.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV,
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://jaeger-collector:4318/v1/traces',
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      // Auto-instrument HTTP, Express, pg, redis, etc.
      '@opentelemetry/instrumentation-http': {
        ignoreIncomingPaths: ['/health', '/metrics'],
      },
    }),
  ],
});

sdk.start();

// ============================================
// Manual span creation for business logic
// ============================================
const tracer = trace.getTracer('api-service');

async function processOrder(orderId: string): Promise<void> {
  // Create a span for the entire operation
  return tracer.startActiveSpan('processOrder', async (span) => {
    try {
      span.setAttribute('order.id', orderId);

      // Child span: validate order
      const order = await tracer.startActiveSpan('validateOrder', async (validateSpan) => {
        const order = await db.orders.findById(orderId);
        validateSpan.setAttribute('order.total', order.total);
        validateSpan.setAttribute('order.items_count', order.items.length);
        validateSpan.end();
        return order;
      });

      // Child span: process payment
      await tracer.startActiveSpan('processPayment', async (paymentSpan) => {
        paymentSpan.setAttribute('payment.method', order.paymentMethod);
        paymentSpan.setAttribute('payment.amount', order.total);

        const result = await paymentService.charge(order);
        paymentSpan.setAttribute('payment.transaction_id', result.transactionId);
        paymentSpan.end();
      });

      // Child span: send notification
      await tracer.startActiveSpan('sendNotification', async (notifSpan) => {
        await notificationService.sendOrderConfirmation(order);
        notifSpan.end();
      });

      span.setStatus({ code: SpanStatusCode.OK });
    } catch (error) {
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message,
      });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}
```

```
Distributed Trace Visualization:

Service: api-gateway  ──────────────────────────────────  350ms
  └─ Service: api-service  ────────────────────────────  320ms
       ├─ validateOrder  ─────────  15ms
       │    └─ DB Query (SELECT)  ──  8ms
       ├─ processPayment  ──────────────────  200ms
       │    └─ HTTP POST payment-service  ──────  195ms
       │         ├─ chargeCard  ────────────  150ms
       │         │    └─ Stripe API call  ──  140ms
       │         └─ updateLedger  ──  30ms
       │              └─ DB Query (INSERT)  ──  25ms
       └─ sendNotification  ─────  80ms
            └─ SQS SendMessage  ──  5ms

Trace ID: abc123def456
Each service propagates the trace ID via headers:
  traceparent: 00-abc123def456-span789-01
```

---

## ELK Stack

```yaml
# docker-compose for ELK Stack
version: '3.9'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.10.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data

  logstash:
    image: docker.elastic.co/logstash/logstash:8.10.0
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.10.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.10.0
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - elasticsearch

volumes:
  elasticsearch-data:
```

```ruby
# logstash/pipeline/logstash.conf
input {
  beats {
    port => 5044
  }

  tcp {
    port => 5000
    codec => json
  }
}

filter {
  # Parse JSON logs
  json {
    source => "message"
  }

  # Add geolocation from IP
  geoip {
    source => "ip"
    target => "geoip"
  }

  # Parse timestamp
  date {
    match => ["timestamp", "ISO8601"]
  }

  # Add environment tag
  mutate {
    add_field => { "environment" => "production" }
  }

  # Remove sensitive fields
  mutate {
    remove_field => ["password", "token", "credit_card"]
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logs-%{[service]}-%{+YYYY.MM.dd}"
  }
}
```

---

# 5. SECURITY

## OWASP Top 10 (2021)

```
┌──────────────────────────────────────────────────────────┐
│                    OWASP TOP 10 (2021)                    │
│                                                           │
│  1. A01 - Broken Access Control                          │
│  2. A02 - Cryptographic Failures                         │
│  3. A03 - Injection (SQL, NoSQL, OS, LDAP)              │
│  4. A04 - Insecure Design                                │
│  5. A05 - Security Misconfiguration                      │
│  6. A06 - Vulnerable/Outdated Components                 │
│  7. A07 - Identification & Authentication Failures       │
│  8. A08 - Software & Data Integrity Failures             │
│  9. A09 - Security Logging & Monitoring Failures         │
│  10. A10 - Server-Side Request Forgery (SSRF)            │
└──────────────────────────────────────────────────────────┘
```

### A01: Broken Access Control

```typescript
// ❌ BAD - No authorization check
app.get('/api/users/:id/profile', async (req, res) => {
  const user = await db.users.findById(req.params.id);
  res.json(user); // Any authenticated user can see any profile!
});

// ✅ GOOD - Proper authorization
app.get('/api/users/:id/profile', authenticate, async (req, res) => {
  const targetUserId = req.params.id;

  // Check if user can access this resource
  if (req.user.id !== targetUserId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Forbidden' });
  }

  const user = await db.users.findById(targetUserId);
  res.json(user);
});

// ❌ BAD - IDOR (Insecure Direct Object Reference)
app.delete('/api/documents/:docId', authenticate, async (req, res) => {
  await db.documents.delete(req.params.docId);  // No ownership check!
  res.status(204).send();
});

// ✅ GOOD - Check ownership
app.delete('/api/documents/:docId', authenticate, async (req, res) => {
  const doc = await db.documents.findById(req.params.docId);

  if (!doc) {
    return res.status(404).json({ error: 'Not found' });
  }

  if (doc.ownerId !== req.user.id) {
    // Don't reveal that the document exists
    return res.status(404).json({ error: 'Not found' });
  }

  await db.documents.delete(req.params.docId);
  res.status(204).send();
});

// Role-based access control middleware
function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
}

app.delete('/api/admin/users/:id',
  authenticate,
  requireRole('admin', 'super_admin'),
  deleteUser
);
```

### A03: Injection

```typescript
// ❌ BAD - SQL Injection
app.get('/api/users', async (req, res) => {
  const name = req.query.name;
  const result = await db.query(
    `SELECT * FROM users WHERE name = '${name}'`
    // Input: ' OR '1'='1' -- drops the whole table
  );
});

// ✅ GOOD - Parameterized queries
app.get('/api/users', async (req, res) => {
  const name = req.query.name;
  const result = await db.query(
    'SELECT * FROM users WHERE name = $1',
    [name]  // Parameters are escaped automatically
  );
});

// ✅ GOOD - Using an ORM (Prisma, TypeORM, etc.)
const users = await prisma.user.findMany({
  where: { name: req.query.name as string },
});

// ❌ BAD - NoSQL Injection (MongoDB)
app.post('/api/login', async (req, res) => {
  const user = await User.findOne({
    username: req.body.username,
    password: req.body.password,
    // Attacker sends: { "password": { "$gt": "" } }
    // This matches ANY password!
  });
});

// ✅ GOOD - Validate and sanitize input
import { z } from 'zod';

const loginSchema = z.object({
  username: z.string().min(3).max(50),
  password: z.string().min(8).max(128),
});

app.post('/api/login', async (req, res) => {
  const { username, password } = loginSchema.parse(req.body);
  // Now username and password are guaranteed to be strings
  const user = await User.findOne({ username });
  if (!user || !await bcrypt.compare(password, user.passwordHash)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
});

// ❌ BAD - Command Injection
app.get('/api/ping', (req, res) => {
  const host = req.query.host;
  exec(`ping -c 1 ${host}`, (err, stdout) => {
    // Input: "google.com; rm -rf /"
    res.send(stdout);
  });
});

// ✅ GOOD - Use safe APIs
import { execFile } from 'child_process';

app.get('/api/ping', (req, res) => {
  const host = req.query.host as string;

  // Validate input
  if (!/^[a-zA-Z0-9.-]+$/.test(host)) {
    return res.status(400).json({ error: 'Invalid host' });
  }

  // execFile doesn't use shell, so no injection possible
  execFile('ping', ['-c', '1', host], (err, stdout) => {
    res.send(stdout);
  });
});
```

### A05: Security Misconfiguration

```typescript
// Express.js security hardening
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import hpp from 'hpp';

const app = express();

// 1. Security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
}));

// 2. CORS configuration
app.use(cors({
  origin: ['https://myapp.com', 'https://admin.myapp.com'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
}));

// 3. Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                    // 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests' },
});
app.use('/api/', limiter);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,                     // 5 login attempts per 15 minutes
});
app.use('/api/auth/login', authLimiter);

// 4. Request size limits
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// 5. HTTP Parameter Pollution protection
app.use(hpp());

// 6. Remove powered-by header
app.disable('x-powered-by');

// 7. Don't expose stack traces in production
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error('Unhandled error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
  });

  res.status(500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'Internal Server Error'
      : err.message,
  });
});
```

---

## Encryption & TLS

```
┌──────────────────────────────────────────────────────┐
│              ENCRYPTION TYPES                         │
│                                                       │
│  ENCRYPTION AT REST                                   │
│  Data stored on disk is encrypted                     │
│  • S3: SSE-S3, SSE-KMS, SSE-C                       │
│  • RDS: AWS KMS encryption                            │
│  • EBS: Encrypted volumes                             │
│  • DynamoDB: AWS owned / customer managed keys        │
│                                                       │
│  ENCRYPTION IN TRANSIT                                │
│  Data moving between systems is encrypted             │
│  • TLS 1.2/1.3 for all HTTPS connections             │
│  • VPN/PrivateLink for inter-service traffic         │
│  • Certificate pinning for mobile apps               │
│                                                       │
│  ENCRYPTION IN USE                                    │
│  Data is encrypted while being processed              │
│  • AWS Nitro Enclaves                                 │
│  • Homomorphic encryption (emerging)                  │
└──────────────────────────────────────────────────────┘
```

```typescript
// Encryption examples
import crypto from 'crypto';

// ============================================
// Password Hashing (NEVER encrypt passwords - HASH them)
// ============================================
import bcrypt from 'bcrypt';

async function hashPassword(password: string): Promise<string> {
  const saltRounds = 12;  // Higher = slower = more secure
  return bcrypt.hash(password, saltRounds);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

// ============================================
// AES-256-GCM Encryption (for data at rest)
// ============================================
class EncryptionService {
  private algorithm = 'aes-256-gcm';

  // Encrypt data
  encrypt(plaintext: string, key: Buffer): { ciphertext: string; iv: string; tag: string } {
    const iv = crypto.randomBytes(16);  // Always use random IV
    const cipher = crypto.createCipheriv(this.algorithm, key, iv);

    let ciphertext = cipher.update(plaintext, 'utf8', 'base64');
    ciphertext += cipher.final('base64');

    return {
      ciphertext,
      iv: iv.toString('base64'),
      tag: cipher.getAuthTag().toString('base64'),
    };
  }

  // Decrypt data
  decrypt(ciphertext: string, key: Buffer, iv: string, tag: string): string {
    const decipher = crypto.createDecipheriv(
      this.algorithm,
      key,
      Buffer.from(iv, 'base64')
    );
    decipher.setAuthTag(Buffer.from(tag, 'base64'));

    let plaintext = decipher.update(ciphertext, 'base64', 'utf8');
    plaintext += decipher.final('utf8');
    return plaintext;
  }
}

// ============================================
// Using AWS KMS for key management
// ============================================
import { KMSClient, GenerateDataKeyCommand, DecryptCommand } from '@aws-sdk/client-kms';

class KMSEncryptionService {
  private kms = new KMSClient({ region: 'us-east-1' });
  private keyId: string;

  constructor(keyId: string) {
    this.keyId = keyId;
  }

  // Generate a data key for envelope encryption
  async encrypt(plaintext: string): Promise<{
    encryptedData: string;
    encryptedDataKey: string;
  }> {
    // KMS generates a data key (plaintext + encrypted version)
    const { Plaintext, CiphertextBlob } = await this.kms.send(
      new GenerateDataKeyCommand({
        KeyId: this.keyId,
        KeySpec: 'AES_256',
      })
    );

    // Use plaintext key to encrypt data locally
    const encService = new EncryptionService();
    const result = encService.encrypt(plaintext, Buffer.from(Plaintext!));

    // Store encrypted data key alongside encrypted data
    // NEVER store the plaintext key!
    return {
      encryptedData: JSON.stringify(result),
      encryptedDataKey: Buffer.from(CiphertextBlob!).toString('base64'),
    };
  }
}
```

### TLS Configuration

```nginx
# nginx.conf - TLS best practices
server {
    listen 443 ssl http2;
    server_name myapp.com;

    # Modern TLS configuration
    ssl_certificate     /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # TLS versions (only 1.2 and 1.3)
    ssl_protocols TLSv1.2 TLSv1.3;

    # Strong cipher suites
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/nginx/ssl/chain.pem;

    # SSL session caching
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name myapp.com;
    return 301 https://$host$request_uri;
}
```

---

## Secrets Management

```typescript
// ============================================
// AWS Secrets Manager
// ============================================
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

class SecretsService {
  private client = new SecretsManagerClient({ region: 'us-east-1' });
  private cache = new Map<string, { value: string; expiry: number }>();
  private cacheTTL = 300_000; // 5 minutes

  async getSecret(secretName: string): Promise<string> {
    // Check cache first
    const cached = this.cache.get(secretName);
    if (cached && cached.expiry > Date.now()) {
      return cached.value;
    }

    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await this.client.send(command);
    const value = response.SecretString!;

    // Cache the secret
    this.cache.set(secretName, {
      value,
      expiry: Date.now() + this.cacheTTL,
    });

    return value;
  }

  async getDatabaseConfig(): Promise<DatabaseConfig> {
    const secret = await this.getSecret('myapp/prod/database');
    return JSON.parse(secret);
  }
}

// ============================================
// Environment-based secrets (for development)
// ============================================

// .env (NEVER commit this file)
// DB_HOST=localhost
// DB_PASSWORD=local_dev_password
// JWT_SECRET=dev-secret-key

// Use dotenv only in development
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

// ============================================
// HashiCorp Vault
// ============================================
import Vault from 'node-vault';

const vault = Vault({
  apiVersion: 'v1',
  endpoint: process.env.VAULT_ADDR,
  token: process.env.VAULT_TOKEN, // Or use AppRole auth
});

async function getDBCredentials() {
  // Dynamic secrets - Vault generates temporary credentials
  const result = await vault.read('database/creds/api-role');
  return {
    username: result.data.username,
    password: result.data.password,
    lease_duration: result.lease_duration,
    // Credentials auto-expire after lease_duration!
  };
}
```

```
Secrets Management Best Practices:
┌─────────────────────────────────────────────────────┐
│                                                      │
│  ✅ DO:                                             │
│  • Use AWS Secrets Manager / HashiCorp Vault        │
│  • Rotate secrets automatically                      │
│  • Use dynamic/temporary credentials when possible   │
│  • Encrypt secrets at rest AND in transit            │
│  • Audit access to secrets                           │
│  • Use separate secrets per environment              │
│  • Use IAM roles instead of access keys              │
│                                                      │
│  ❌ DON'T:                                          │
│  • Hardcode secrets in source code                   │
│  • Commit .env files to git                          │
│  • Log secrets                                       │
│  • Share secrets via Slack/email                      │
│  • Use same secrets across environments              │
│  • Store secrets in plain-text config files           │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Authentication vs Authorization

```
┌──────────────────────────────────────────────────────────┐
│          AUTHENTICATION vs AUTHORIZATION                  │
│                                                           │
│  AUTHENTICATION (AuthN)      AUTHORIZATION (AuthZ)       │
│  "Who are you?"              "What can you do?"          │
│                                                           │
│  Verifies identity           Verifies permissions         │
│                                                           │
│  Methods:                    Methods:                     │
│  • Username/Password         • RBAC (Role-Based)         │
│  • OAuth 2.0 / OIDC         • ABAC (Attribute-Based)    │
│  • SAML                     • Policy-Based (OPA)         │
│  • API Keys                 • ACLs                       │
│  • MFA/2FA                  • Scopes (OAuth)             │
│  • Certificates             • Resource ownership         │
│                                                           │
│  Happens FIRST              Happens AFTER authentication │
│  401 Unauthorized            403 Forbidden                │
└──────────────────────────────────────────────────────────┘
```

```typescript
// Complete Auth implementation
import jwt from 'jsonwebtoken';
import bcrypt from 'bcrypt';

interface TokenPayload {
  userId: string;
  email: string;
  role: string;
  permissions: string[];
}

// ============================================
// JWT Authentication
// ============================================
class AuthService {
  private readonly accessTokenSecret = process.env.JWT_ACCESS_SECRET!;
  private readonly refreshTokenSecret = process.env.JWT_REFRESH_SECRET!;

  async login(email: string, password: string): Promise<AuthTokens> {
    const user = await db.users.findByEmail(email);

    if (!user) {
      // Use same error message to prevent user enumeration
      throw new UnauthorizedError('Invalid credentials');
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      // Track failed attempts for brute force protection
      await this.trackFailedLogin(email);
      throw new UnauthorizedError('Invalid credentials');
    }

    // Check if account is locked
    if (user.lockedUntil && user.lockedUntil > new Date()) {
      throw new UnauthorizedError('Account temporarily locked');
    }

    // Generate tokens
    const accessToken = this.generateAccessToken(user);
    const refreshToken = this.generateRefreshToken(user);

    // Store refresh token hash in DB (for revocation)
    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    await db.refreshTokens.create({
      userId: user.id,
      tokenHash: refreshTokenHash,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    });

    return { accessToken, refreshToken };
  }

  generateAccessToken(user: User): string {
    const payload: TokenPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
      permissions: user.permissions,
    };

    return jwt.sign(payload, this.accessTokenSecret, {
      expiresIn: '15m',      // Short-lived!
      issuer: 'myapp',
      audience: 'myapp-api',
    });
  }

  generateRefreshToken(user: User): string {
    return jwt.sign(
      { userId: user.id, type: 'refresh' },
      this.refreshTokenSecret,
      { expiresIn: '7d' }
    );
  }

  async refreshAccessToken(refreshToken: string): Promise<string> {
    const payload = jwt.verify(refreshToken, this.refreshTokenSecret) as any;

    // Check if refresh token is in DB (not revoked)
    const storedTokens = await db.refreshTokens.findByUserId(payload.userId);
    const isValid = await Promise.any(
      storedTokens.map(t => bcrypt.compare(refreshToken, t.tokenHash))
    ).catch(() => false);

    if (!isValid) {
      // Possible token theft - revoke ALL refresh tokens for this user
      await db.refreshTokens.deleteByUserId(payload.userId);
      throw new UnauthorizedError('Invalid refresh token');
    }

    const user = await db.users.findById(payload.userId);
    return this.generateAccessToken(user);
  }

  async logout(userId: string, refreshToken: string): Promise<void> {
    // Revoke the specific refresh token
    const storedTokens = await db.refreshTokens.findByUserId(userId);
    for (const stored of storedTokens) {
      if (await bcrypt.compare(refreshToken, stored.tokenHash)) {
        await db.refreshTokens.delete(stored.id);
        break;
      }
    }
  }

  private async trackFailedLogin(email: string): Promise<void> {
    const key = `failed_login:${email}`;
    const attempts = await redis.incr(key);
    await redis.expire(key, 900); // 15 minute window

    if (attempts >= 5) {
      // Lock account for 15 minutes
      await db.users.update(
        { email },
        { lockedUntil: new Date(Date.now() + 15 * 60 * 1000) }
      );
    }
  }
}

// ============================================
// Authentication Middleware
// ============================================
async function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization header' });
  }

  const token = authHeader.substring(7);

  try {
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET!, {
      issuer: 'myapp',
      audience: 'myapp-api',
    }) as TokenPayload;

    req.user = payload;
    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// ============================================
// Authorization Middleware (RBAC + Permissions)
// ============================================
function authorize(...requiredPermissions: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = req.user as TokenPayload;

    if (!user) {
      return res.status(401).json({ error: 'Not authenticated' });
    }

    // Admin bypasses permission checks
    if (user.role === 'admin') {
      return next();
    }

    const hasPermission = requiredPermissions.every(
      perm => user.permissions.includes(perm)
    );

    if (!hasPermission) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    next();
  };
}

// Usage
app.get('/api/users',
  authenticate,
  authorize('users:read'),
  listUsers
);

app.delete('/api/users/:id',
  authenticate,
  authorize('users:delete'),
  deleteUser
);

app.post('/api/admin/reports',
  authenticate,
  authorize('reports:create', 'admin:access'),
  createReport
);
```

### OAuth 2.0 Flow

```
┌──────────────────────────────────────────────────────────┐
│               OAuth 2.0 Authorization Code Flow           │
│               (with PKCE - recommended)                   │
│                                                           │
│  ┌──────┐                ┌───────┐         ┌─────────┐  │
│  │ User │                │  App  │         │  Auth   │  │
│  │      │                │(Client)│        │ Server  │  │
│  └──┬───┘                └───┬───┘         └────┬────┘  │
│     │  1. Click "Login"      │                   │       │
│     │───────────────────────▶│                   │       │
│     │                        │                   │       │
│     │  2. Redirect to Auth Server                │       │
│     │◀───────────────────────│                   │       │
│     │    (with code_challenge)                   │       │
│     │                        │                   │       │
│     │  3. Login + Consent    │                   │       │
│     │───────────────────────────────────────────▶│       │
│     │                        │                   │       │
│     │  4. Redirect back with authorization code  │       │
│     │◀──────────────────────────────────────────│       │
│     │                        │                   │       │
│     │  5. Forward code       │                   │       │
│     │───────────────────────▶│                   │       │
│     │                        │                   │       │
│     │                        │ 6. Exchange code  │       │
│     │                        │    + code_verifier│       │
│     │                        │──────────────────▶│       │
│     │                        │                   │       │
│     │                        │ 7. Access Token + │       │
│     │                        │    Refresh Token  │       │
│     │                        │◀──────────────────│       │
│     │                        │                   │       │
│     │  8. Authenticated!     │                   │       │
│     │◀───────────────────────│                   │       │
│     │                        │                   │       │
└──────────────────────────────────────────────────────────┘
```

---

## Security Checklist for Lead Engineers

```
┌──────────────────────────────────────────────────────────┐
│            PRODUCTION SECURITY CHECKLIST                   │
│                                                           │
│  INFRASTRUCTURE                                           │
│  □ TLS 1.2+ everywhere (no exceptions)                   │
│  □ WAF configured (AWS WAF / Cloudflare)                 │
│  □ DDoS protection enabled                               │
│  □ VPC with private subnets for backend services         │
│  □ Security groups with least-privilege rules            │
│  □ No public S3 buckets                                   │
│  □ Encryption at rest for all data stores                │
│  □ VPN/bastion for SSH access                            │
│                                                           │
│  APPLICATION                                              │
│  □ Input validation on ALL endpoints                     │
│  □ Parameterized queries (no string concatenation)       │
│  □ Rate limiting on all APIs                              │
│  □ CORS properly configured                              │
│  □ Security headers (Helmet.js / similar)                │
│  □ No sensitive data in logs                              │
│  □ CSRF protection for stateful sessions                 │
│  □ File upload validation (type, size, content)          │
│                                                           │
│  AUTHENTICATION                                           │
│  □ Passwords hashed with bcrypt/scrypt/argon2            │
│  □ JWT with short expiry + refresh tokens                │
│  □ MFA available for sensitive operations                │
│  □ Account lockout after failed attempts                 │
│  □ Secure password reset flow                            │
│                                                           │
│  SECRETS                                                  │
│  □ No hardcoded secrets in code                          │
│  □ Secrets in Secrets Manager / Vault                    │
│  □ Automated secret rotation                              │
│  □ API keys scoped with minimum permissions              │
│                                                           │
│  CI/CD                                                    │
│  □ Dependency vulnerability scanning (Snyk/Dependabot)   │
│  □ Container image scanning (Trivy)                      │
│  □ SAST (Static Application Security Testing)            │
│  □ DAST (Dynamic Application Security Testing)           │
│  □ No secrets in CI/CD logs                              │
│                                                           │
│  MONITORING                                               │
│  □ Security event logging                                │
│  □ Alerting on auth failures                             │
│  □ Alerting on privilege escalation                      │
│  □ Regular security audits                                │
│  □ Incident response plan documented                     │
└──────────────────────────────────────────────────────────┘
```

---

## Complete Observability Stack (Docker Compose)

```yaml
# docker-compose.observability.yml
version: '3.9'

services:
  # Your application
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
      - LOG_LEVEL=info

  # OpenTelemetry Collector (central telemetry pipeline)
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    volumes:
      - ./otel-config.yml:/etc/otelcol-contrib/config.yaml
    ports:
      - "4317:4317"   # gRPC
      - "4318:4318"   # HTTP

  # Prometheus (metrics)
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert_rules.yml:/etc/prometheus/alert_rules.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"

  # Grafana (dashboards)
  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

  # Jaeger (distributed tracing)
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # UI
      - "14268:14268"  # Collector

  # Alertmanager
  alertmanager:
    image: prom/alertmanager:latest
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"

  # Loki (log aggregation - lighter than ELK)
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki

  # Promtail (log shipper to Loki)
  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail-config.yml:/etc/promtail/config.yml

volumes:
  prometheus-data:
  grafana-data:
  loki-data:
```

---

This guide covers the essential knowledge a backend lead engineer needs across Docker, CI/CD, AWS, observability, and security. Each section includes practical, production-ready examples that can be adapted to real-world systems.