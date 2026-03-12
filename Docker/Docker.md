

# The Complete Docker Mastery Guide
## From Beginner to Confident Practitioner

---

## Table of Contents

1. [Docker Fundamentals & Architecture](#1-docker-fundamentals--architecture)
2. [Docker Installation & Setup](#2-docker-installation--setup)
3. [Docker Images](#3-docker-images)
4. [Docker Containers](#4-docker-containers)
5. [Dockerfile — Building Custom Images](#5-dockerfile--building-custom-images)
6. [Docker Volumes & Data Persistence](#6-docker-volumes--data-persistence)
7. [Docker Networking](#7-docker-networking)
8. [Docker Compose](#8-docker-compose)
9. [Docker Registry](#9-docker-registry)
10. [Docker Security Best Practices](#10-docker-security-best-practices)
11. [Docker Orchestration](#11-docker-orchestration)
12. [Troubleshooting & Debugging](#12-troubleshooting--debugging)
13. [Real-World Project Example](#13-real-world-project-example)
14. [Quick Reference Cheat Sheet](#14-quick-reference-cheat-sheet)

---

## 1. Docker Fundamentals & Architecture

### What Is Docker?

Docker is a platform that lets you **package an application and all its dependencies** (libraries, configuration files, runtime) into a standardized unit called a **container**. Think of it like a shipping container for software — no matter where you send it, everything inside stays the same and works the same way.

### Why Docker Matters

```
Traditional Deployment Problems        Docker Solutions
─────────────────────────────────      ──────────────────────────────
"It works on my machine!"         →    Same environment everywhere
Dependency conflicts              →    Isolated dependencies per app
Slow setup for new developers     →    One command to start everything
Resource-heavy virtual machines   →    Lightweight containers
Inconsistent environments        →    Reproducible builds every time
```

### Docker Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      DOCKER CLIENT                          │
│              (docker build, run, pull, push)                 │
└────────────────────────┬────────────────────────────────────┘
                         │ REST API
┌────────────────────────▼────────────────────────────────────┐
│                     DOCKER DAEMON (dockerd)                  │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │   IMAGES     │  │  CONTAINERS  │  │    NETWORKS        │  │
│  │              │  │              │  │                     │  │
│  │ nginx:latest │  │ web-server   │  │  bridge, host,     │  │
│  │ python:3.11  │  │ database     │  │  overlay, custom   │  │
│  │ node:20      │  │ cache        │  │                     │  │
│  └──────────────┘  └──────────────┘  └───────────────────┘  │
│                                                              │
│  ┌──────────────┐                                            │
│  │   VOLUMES    │                                            │
│  │              │                                            │
│  │ db-data      │                                            │
│  │ app-logs     │                                            │
│  └──────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
                         │
          ┌──────────────▼──────────────┐
          │      DOCKER REGISTRY        │
          │    (Docker Hub, ECR, etc.)   │
          └─────────────────────────────┘
```

### Key Concepts at a Glance

| Concept | What It Is | Real-World Analogy |
|---------|-----------|-------------------|
| **Image** | A read-only blueprint/template | A recipe for a dish |
| **Container** | A running instance of an image | The dish itself |
| **Dockerfile** | Instructions to build an image | The step-by-step recipe card |
| **Volume** | Persistent storage for data | An external hard drive |
| **Network** | Communication channel between containers | A private phone line |
| **Registry** | A storage location for images | An app store for images |
| **Compose** | Tool to define multi-container apps | A meal plan with multiple recipes |

### Containers vs. Virtual Machines

```
   VIRTUAL MACHINES                    CONTAINERS
┌────────┬────────┬────────┐     ┌────────┬────────┬────────┐
│  App A │  App B │  App C │     │  App A │  App B │  App C │
├────────┼────────┼────────┤     ├────────┼────────┼────────┤
│Guest OS│Guest OS│Guest OS│     │ Bins/  │ Bins/  │ Bins/  │
│ (full) │ (full) │ (full) │     │  Libs  │  Libs  │  Libs  │
├────────┴────────┴────────┤     ├────────┴────────┴────────┤
│       HYPERVISOR         │     │     CONTAINER ENGINE      │
├──────────────────────────┤     │       (Docker)            │
│       HOST OS            │     ├──────────────────────────┤
├──────────────────────────┤     │       HOST OS             │
│     INFRASTRUCTURE       │     ├──────────────────────────┤
└──────────────────────────┘     │     INFRASTRUCTURE        │
                                 └──────────────────────────┘

  • Each VM: 1-20+ GB                • Each container: 5-500 MB
  • Boot time: minutes               • Start time: seconds
  • Full OS per VM                    • Shared OS kernel
  • Strong isolation                  • Process-level isolation
```

---

## 2. Docker Installation & Setup

### Installing Docker

**On Ubuntu/Debian:**
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group (avoids needing sudo)
sudo usermod -aG docker $USER

# Log out and back in, then verify
docker --version
```

**On macOS:** Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/)

**On Windows:** Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (requires WSL2)

### Verifying Your Installation

```bash
# Check Docker version
docker --version
# Output: Docker version 24.0.7, build afdd53b

# Check detailed version info
docker version

# View system-wide information
docker info

# Run the hello-world test container
docker run hello-world
```

**What happens when you run `docker run hello-world`:**

```
1. Docker client contacts Docker daemon
2. Daemon looks for "hello-world" image locally → not found
3. Daemon pulls "hello-world" from Docker Hub
4. Daemon creates a container from the image
5. Container runs, prints a message, then exits
```

---

## 3. Docker Images

### What Is a Docker Image?

An image is a **read-only template** containing everything needed to run an application: the code, runtime, system libraries, and settings. Images are built in **layers**, where each layer represents a change or instruction.

```
┌──────────────────────────────────┐
│  Layer 5: COPY app files         │  ← Your application code
├──────────────────────────────────┤
│  Layer 4: RUN npm install        │  ← Dependencies
├──────────────────────────────────┤
│  Layer 3: WORKDIR /app           │  ← Working directory
├──────────────────────────────────┤
│  Layer 2: RUN apt-get install    │  ← System packages
├──────────────────────────────────┤
│  Layer 1: Ubuntu 22.04 base      │  ← Base operating system
└──────────────────────────────────┘
```

Each layer is **cached**. If nothing changes in a layer, Docker reuses it — this makes builds faster.

### Essential Image Commands

#### Pulling Images (Downloading from a Registry)

```bash
# Pull the latest version of an image
docker pull nginx
# This is the same as:
docker pull nginx:latest

# Pull a specific version (tag)
docker pull nginx:1.25.3

# Pull a lightweight Alpine-based image
docker pull nginx:alpine

# Pull from a specific registry
docker pull registry.example.com/myapp:v2.0

# Pull an image for a specific platform
docker pull --platform linux/arm64 nginx:latest
```

#### Listing Images

```bash
# List all local images
docker images
# Or use the newer command:
docker image ls

# EXAMPLE OUTPUT:
# REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
# nginx        latest    a8758716bb6a   2 weeks ago    187MB
# nginx        alpine    1e4e3d3c4a2b   2 weeks ago    43.2MB
# python       3.11      f3d4e8c2b1a0   3 days ago     1.01GB
# node         20        b2c5d7e8f9a1   5 days ago     1.1GB

# List images with filtering
docker images --filter "dangling=true"     # Untagged images
docker images --filter "reference=nginx"   # Only nginx images

# Show image IDs only (useful for scripting)
docker images -q

# Show full image details including all tags
docker images --no-trunc

# Show image sizes and digests
docker images --digests
```

#### Inspecting Images

```bash
# View detailed information about an image
docker image inspect nginx:latest

# View the build history (layers) of an image
docker image history nginx:latest

# EXAMPLE OUTPUT:
# IMAGE          CREATED       CREATED BY                                      SIZE
# a8758716bb6a   2 weeks ago   CMD ["nginx" "-g" "daemon off;"]                0B
# <missing>      2 weeks ago   EXPOSE map[80/tcp:{}]                           0B
# <missing>      2 weeks ago   STOPSIGNAL SIGQUIT                              0B
# <missing>      2 weeks ago   RUN /bin/sh -c set -x && addgroup...            62.1MB
# <missing>      2 weeks ago   ENV NGINX_VERSION=1.25.3                        0B

# Get specific information using format
docker image inspect nginx --format '{{.Architecture}}'
# Output: amd64

docker image inspect nginx --format '{{.Config.ExposedPorts}}'
# Output: map[80/tcp:{}]

docker image inspect nginx --format '{{.RootFS.Layers}}' 
# Shows all layer SHAs
```

#### Tagging Images

```bash
# Tag an image with a new name
docker tag nginx:latest my-nginx:v1.0

# Tag for pushing to a private registry
docker tag myapp:latest registry.example.com/myapp:v1.0

# Tag with multiple tags
docker tag myapp:latest myapp:v2.0
docker tag myapp:latest myapp:stable
```

#### Removing Images

```bash
# Remove a specific image
docker rmi nginx:latest
# Or:
docker image rm nginx:latest

# Remove multiple images
docker rmi nginx python:3.11 node:20

# Force remove (even if containers reference it)
docker rmi -f nginx:latest

# Remove ALL unused images (not referenced by any container)
docker image prune

# Remove ALL images (including ones that might be used)
docker image prune -a

# Remove images older than 24 hours
docker image prune -a --filter "until=24h"

# Remove ALL images forcefully (nuclear option)
docker rmi $(docker images -q) -f
```

#### Saving and Loading Images

```bash
# Save an image to a tar file (for offline transfer)
docker save nginx:latest -o nginx-image.tar
docker save nginx:latest > nginx-image.tar

# Load an image from a tar file
docker load -i nginx-image.tar
docker load < nginx-image.tar

# Export a container's filesystem (not the same as save!)
docker export my-container -o container-fs.tar

# Import a filesystem as a new image
docker import container-fs.tar my-new-image:latest
```

### Understanding Image Naming

```
registry.example.com/organization/image-name:tag
│                    │              │          │
│                    │              │          └─ Version/variant (default: latest)
│                    │              └─ Image name
│                    └─ Organization/username
└─ Registry (default: docker.io)

EXAMPLES:
  nginx                          → docker.io/library/nginx:latest
  myuser/myapp:v2.0              → docker.io/myuser/myapp:v2.0
  gcr.io/my-project/api:1.0      → Google Container Registry
  123456789.dkr.ecr.us-east-1.amazonaws.com/app:prod → AWS ECR
```

---

## 4. Docker Containers

### What Is a Container?

A container is a **running instance of an image**. While an image is a static blueprint, a container is the live, running process. You can create multiple containers from the same image, each isolated from the others.

```
         Docker Image: nginx:latest
         ┌─────────────────────────┐
         │   Read-Only Template    │
         └────┬──────┬──────┬──────┘
              │      │      │
              ▼      ▼      ▼
         ┌────┐  ┌────┐  ┌────┐
         │ C1 │  │ C2 │  │ C3 │   ← Three separate containers
         │web1│  │web2│  │web3│      from the same image
         └────┘  └────┘  └────┘
```

### Creating and Running Containers

#### The `docker run` Command (Most Important!)

```bash
# Basic syntax
docker run [OPTIONS] IMAGE [COMMAND] [ARGS]

# ─── BASIC EXAMPLES ───

# Run a container in the foreground
docker run nginx

# Run in the background (detached mode) — most common
docker run -d nginx

# Run with a custom name
docker run -d --name my-web-server nginx

# Run and automatically remove when stopped
docker run --rm nginx

# Run interactively with a terminal
docker run -it ubuntu bash
# -i = interactive (keep STDIN open)
# -t = allocate a pseudo-TTY (terminal)
```

#### Port Mapping

```bash
# Map host port 8080 to container port 80
docker run -d -p 8080:80 nginx
# Now visit http://localhost:8080

# Map multiple ports
docker run -d -p 8080:80 -p 8443:443 nginx

# Map to a specific host interface
docker run -d -p 127.0.0.1:8080:80 nginx

# Let Docker choose a random host port
docker run -d -p 80 nginx
# Check which port was assigned with: docker port <container>

# Publish all exposed ports to random ports
docker run -d -P nginx

# Map a range of ports
docker run -d -p 8080-8090:80-90 nginx
```

**Port mapping diagram:**
```
HOST MACHINE                     CONTAINER
┌──────────────────┐            ┌──────────────────┐
│                  │            │                  │
│  localhost:8080 ─┼────────────┼─► port 80        │
│                  │  -p 8080:80│                  │
│  localhost:8443 ─┼────────────┼─► port 443       │
│                  │ -p 8443:443│                  │
└──────────────────┘            └──────────────────┘
```

#### Environment Variables

```bash
# Set environment variables
docker run -d \
    -e MYSQL_ROOT_PASSWORD=secret \
    -e MYSQL_DATABASE=myapp \
    -e MYSQL_USER=admin \
    -e MYSQL_PASSWORD=adminpass \
    --name my-database \
    mysql:8.0

# Load environment variables from a file
# First, create an .env file:
cat > app.env << EOF
DB_HOST=database
DB_PORT=3306
DB_NAME=myapp
DB_USER=admin
DB_PASS=secret123
APP_ENV=production
EOF

# Then use it:
docker run -d --env-file app.env --name my-app myapp:latest

# Verify environment variables inside a container
docker exec my-database env
```

#### Resource Limits

```bash
# Limit memory
docker run -d --memory="512m" nginx
docker run -d --memory="2g" mysql:8.0

# Limit CPU
docker run -d --cpus="1.5" nginx         # Use at most 1.5 CPUs
docker run -d --cpu-shares=512 nginx      # Relative weight (default 1024)

# Combine memory and CPU limits
docker run -d \
    --name limited-app \
    --memory="256m" \
    --memory-swap="512m" \
    --cpus="0.5" \
    nginx

# Set restart policy
docker run -d --restart=always nginx        # Always restart
docker run -d --restart=unless-stopped nginx # Restart unless manually stopped
docker run -d --restart=on-failure:5 nginx   # Restart on failure, max 5 times
```

### Managing Running Containers

#### Listing Containers

```bash
# List running containers
docker ps
# Or:
docker container ls

# EXAMPLE OUTPUT:
# CONTAINER ID   IMAGE   COMMAND                  STATUS          PORTS                  NAMES
# a1b2c3d4e5f6   nginx   "/docker-entrypoint.…"   Up 2 hours      0.0.0.0:8080->80/tcp   my-web

# List ALL containers (including stopped)
docker ps -a

# List only container IDs
docker ps -q

# Show latest created container
docker ps -l

# Filter containers
docker ps --filter "status=running"
docker ps --filter "name=web"
docker ps --filter "ancestor=nginx"

# Custom format output
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Show container sizes
docker ps -s
```

#### Starting, Stopping, and Restarting

```bash
# Stop a running container (sends SIGTERM, then SIGKILL after 10s)
docker stop my-web-server

# Stop with a custom timeout (wait 30 seconds before killing)
docker stop -t 30 my-web-server

# Start a stopped container
docker start my-web-server

# Restart a container
docker restart my-web-server

# Pause a container (freezes all processes)
docker pause my-web-server

# Unpause a container
docker unpause my-web-server

# Kill a container immediately (sends SIGKILL)
docker kill my-web-server

# Stop all running containers
docker stop $(docker ps -q)
```

#### Executing Commands Inside Containers

```bash
# Run a command in a running container
docker exec my-web-server ls /usr/share/nginx/html

# Open an interactive shell
docker exec -it my-web-server bash
# Or if bash is not available (Alpine images):
docker exec -it my-web-server sh

# Run a command as a specific user
docker exec -u root my-web-server whoami

# Set environment variables for the exec command
docker exec -e MY_VAR=hello my-web-server env

# Run a command in a specific working directory
docker exec -w /etc/nginx my-web-server cat nginx.conf
```

#### Viewing Container Information

```bash
# View container logs
docker logs my-web-server

# Follow logs in real-time (like tail -f)
docker logs -f my-web-server

# Show last 50 lines
docker logs --tail 50 my-web-server

# Show logs with timestamps
docker logs -t my-web-server

# Show logs since a specific time
docker logs --since "2024-01-01T00:00:00" my-web-server
docker logs --since "10m" my-web-server   # Last 10 minutes

# View resource usage statistics
docker stats
docker stats my-web-server

# EXAMPLE OUTPUT:
# CONTAINER    CPU %   MEM USAGE / LIMIT    MEM %   NET I/O          BLOCK I/O
# my-web       0.00%   3.5MiB / 7.77GiB     0.04%   1.2kB / 648B     0B / 0B

# View detailed container configuration
docker inspect my-web-server

# Get specific information
docker inspect --format '{{.NetworkSettings.IPAddress}}' my-web-server
docker inspect --format '{{.State.Status}}' my-web-server
docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-web-server

# View port mappings
docker port my-web-server

# View running processes inside a container
docker top my-web-server

# View filesystem changes made in a container
docker diff my-web-server
# A = Added, C = Changed, D = Deleted
```

#### Copying Files

```bash
# Copy file FROM container to host
docker cp my-web-server:/etc/nginx/nginx.conf ./nginx.conf

# Copy file FROM host to container
docker cp ./index.html my-web-server:/usr/share/nginx/html/index.html

# Copy an entire directory
docker cp my-web-server:/var/log/nginx/ ./nginx-logs/
docker cp ./config/ my-web-server:/etc/app/config/
```

#### Removing Containers

```bash
# Remove a stopped container
docker rm my-web-server

# Force remove a running container
docker rm -f my-web-server

# Remove a container and its volumes
docker rm -v my-web-server

# Remove all stopped containers
docker container prune

# Remove all stopped containers (alternative)
docker rm $(docker ps -aq --filter "status=exited")

# Remove ALL containers (running and stopped)
docker rm -f $(docker ps -aq)
```

### Practical Container Example

```bash
# Let's set up a quick web server

# 1. Run nginx with custom content
echo "<h1>Hello from Docker!</h1>" > index.html
docker run -d \
    --name my-website \
    -p 8080:80 \
    -v $(pwd)/index.html:/usr/share/nginx/html/index.html:ro \
    nginx:alpine

# 2. Test it
curl http://localhost:8080
# Output: <h1>Hello from Docker!</h1>

# 3. Check logs
docker logs my-website

# 4. View resource usage
docker stats my-website --no-stream

# 5. Open a shell inside
docker exec -it my-website sh

# 6. Clean up
docker stop my-website && docker rm my-website
```

---

## 5. Dockerfile — Building Custom Images

### What Is a Dockerfile?

A Dockerfile is a **text file with instructions** that Docker reads to automatically build an image. Each instruction creates a new layer in the image. Think of it as a recipe that Docker follows step by step.

### Dockerfile Instructions Reference

```dockerfile
# ─────────────────────────────────────────────────────────────
# INSTRUCTION        PURPOSE
# ─────────────────────────────────────────────────────────────
# FROM               Set the base image
# WORKDIR            Set the working directory
# COPY               Copy files from host to image
# ADD                Copy files (supports URLs and auto-extract tar)
# RUN                Execute commands during build
# ENV                Set environment variables
# ARG                Define build-time variables
# EXPOSE             Document which ports the container listens on
# CMD                Default command to run when container starts
# ENTRYPOINT         Configure the container as an executable
# VOLUME             Create a mount point for volumes
# USER               Set the user for subsequent instructions
# LABEL              Add metadata to the image
# HEALTHCHECK        Define how to check if container is healthy
# SHELL              Override the default shell
# STOPSIGNAL         Set the system call signal to stop the container
# ─────────────────────────────────────────────────────────────
```

### Example 1: Simple Python Application

**Project structure:**
```
my-python-app/
├── Dockerfile
├── requirements.txt
├── app.py
└── templates/
    └── index.html
```

**app.py:**
```python
from flask import Flask, render_template
import os

app = Flask(__name__)

@app.route('/')
def home():
    return render_template('index.html', 
                           hostname=os.environ.get('HOSTNAME', 'unknown'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**requirements.txt:**
```
flask==3.0.0
gunicorn==21.2.0
```

**Dockerfile:**
```dockerfile
# ── Stage: Production Image ──

# 1. Start from a Python base image
FROM python:3.11-slim

# 2. Add metadata labels
LABEL maintainer="yourname@example.com"
LABEL version="1.0"
LABEL description="A simple Flask web application"

# 3. Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    APP_ENV=production

# 4. Set the working directory inside the container
WORKDIR /app

# 5. Copy requirements first (for better layer caching)
#    This layer only rebuilds when requirements.txt changes
COPY requirements.txt .

# 6. Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 7. Copy the rest of the application code
COPY . .

# 8. Create a non-root user for security
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# 9. Switch to non-root user
USER appuser

# 10. Document the port (doesn't actually publish it)
EXPOSE 5000

# 11. Add a health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# 12. Set the default command
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

**Build and run:**
```bash
# Build the image
docker build -t my-python-app:1.0 .

# Run the container
docker run -d -p 5000:5000 --name flask-app my-python-app:1.0

# Test it
curl http://localhost:5000
```

### Example 2: Node.js Application

```dockerfile
FROM node:20-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies (copy package files first for caching)
COPY package*.json ./
RUN npm ci --only=production

# Bundle app source
COPY . .

# Create non-root user
RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup
USER nodeuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
```

### Example 3: Multi-Stage Build (Advanced but Important!)

Multi-stage builds let you use multiple FROM statements to create smaller, more secure production images. You build in one stage and copy only what you need to the final stage.

```dockerfile
# ══════════════════════════════════════
# STAGE 1: Build Stage
# ══════════════════════════════════════
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build
# This creates a /app/dist folder with static files

# ══════════════════════════════════════
# STAGE 2: Production Stage
# ══════════════════════════════════════
FROM nginx:alpine AS production

# Copy ONLY the built files from the builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

# RESULT:
# Builder stage: ~400MB (has Node.js, npm, dev dependencies)
# Final image:   ~25MB  (only nginx + static files)
```

**Why multi-stage builds matter:**
```
WITHOUT Multi-Stage          WITH Multi-Stage
┌──────────────────┐        ┌──────────────────┐
│ Node.js runtime  │        │ Nginx only       │
│ npm              │        │ Built HTML/CSS/JS │
│ node_modules     │        │                  │
│ Source code      │        │                  │
│ Build tools      │        │                  │
│ Built files      │        │                  │
│                  │        │                  │
│   ~400MB         │        │   ~25MB          │
└──────────────────┘        └──────────────────┘
```

### Example 4: Go Application (Multi-Stage)

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

# Production stage — using scratch (empty) image!
FROM scratch

COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 8080

ENTRYPOINT ["/server"]

# Final image: ~10-15MB (just the compiled binary!)
```

### Building Images

```bash
# Build from current directory
docker build -t myapp:latest .

# Build with a specific Dockerfile
docker build -f Dockerfile.production -t myapp:prod .

# Build with build arguments
docker build --build-arg APP_VERSION=2.0 -t myapp:2.0 .
# In Dockerfile: ARG APP_VERSION

# Build without using cache (fresh build)
docker build --no-cache -t myapp:latest .

# Build with a specific target stage (multi-stage)
docker build --target builder -t myapp:builder .

# Build and show build output
docker build --progress=plain -t myapp:latest .

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 \
    -t myapp:latest --push .
```

### CMD vs ENTRYPOINT

```dockerfile
# CMD — Provides defaults, can be overridden
CMD ["python", "app.py"]
# docker run myapp                    → runs: python app.py
# docker run myapp python test.py     → runs: python test.py (overridden)

# ENTRYPOINT — Always runs, not easily overridden
ENTRYPOINT ["python"]
CMD ["app.py"]
# docker run myapp                    → runs: python app.py
# docker run myapp test.py            → runs: python test.py
# docker run --entrypoint bash myapp  → overrides entrypoint

# Best practice: Use ENTRYPOINT + CMD together
ENTRYPOINT ["gunicorn"]
CMD ["--bind", "0.0.0.0:5000", "app:app"]
# docker run myapp                              → gunicorn --bind 0.0.0.0:5000 app:app
# docker run myapp --bind 0.0.0.0:8080 app:app  → gunicorn --bind 0.0.0.0:8080 app:app
```

### Dockerfile Best Practices

```dockerfile
# ✅ DO: Use specific base image tags
FROM python:3.11-slim
# ❌ DON'T: FROM python (uses :latest, unpredictable)

# ✅ DO: Combine RUN commands to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget && \
    rm -rf /var/lib/apt/lists/*
# ❌ DON'T: Separate RUN for each command (creates unnecessary layers)

# ✅ DO: Copy dependency files first, then code (better caching)
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
# ❌ DON'T: COPY everything first (any code change invalidates pip install cache)

# ✅ DO: Use .dockerignore to exclude unnecessary files
# ❌ DON'T: Copy node_modules, .git, etc. into the image

# ✅ DO: Run as non-root user
RUN adduser --system appuser
USER appuser
# ❌ DON'T: Run as root in production

# ✅ DO: Use multi-stage builds for compiled languages
# ❌ DON'T: Include build tools in production images
```

### The .dockerignore File

```
# .dockerignore — works like .gitignore
# Prevents unnecessary files from being sent to the Docker daemon

# Version control
.git
.gitignore

# Dependencies (will be installed in container)
node_modules
__pycache__
*.pyc
venv/

# IDE files
.vscode
.idea
*.swp

# Docker files
Dockerfile*
docker-compose*
.dockerignore

# Documentation
README.md
docs/
LICENSE

# Build artifacts
dist/
build/
*.log

# Environment files with secrets
.env
.env.local
*.secret
```

---

## 6. Docker Volumes & Data Persistence

### The Problem: Container Data Is Temporary

```
Without Volumes:
┌──────────────────────┐
│     Container        │
│  ┌────────────────┐  │
│  │   Writable     │  │    When container is removed,
│  │   Layer        │  │ ←  ALL data in this layer is LOST!
│  │  (your data)   │  │
│  └────────────────┘  │
│  ┌────────────────┐  │
│  │  Image Layers  │  │    (Read-only, shared between containers)
│  │  (read-only)   │  │
│  └────────────────┘  │
└──────────────────────┘

With Volumes:
┌──────────────────────┐        ┌──────────────────┐
│     Container        │        │   Docker Volume   │
│  ┌────────────────┐  │        │                  │
│  │   /app/data ───┼──┼────────┼── Persistent!    │
│  │                │  │        │   Survives       │
│  └────────────────┘  │        │   container      │
│  ┌────────────────┐  │        │   removal        │
│  │  Image Layers  │  │        │                  │
│  └────────────────┘  │        └──────────────────┘
└──────────────────────┘
```

### Three Types of Storage

```
┌─────────────────────────────────────────────────────────────┐
│                     DOCKER HOST                             │
│                                                             │
│  1. VOLUMES (Managed by Docker — RECOMMENDED)               │
│     /var/lib/docker/volumes/my-vol/_data                    │
│     ┌──────────┐                                            │
│     │ my-vol   │ ←── docker volume create my-vol            │
│     └──────────┘                                            │
│                                                             │
│  2. BIND MOUNTS (Direct host path mapping)                  │
│     /home/user/project/data                                 │
│     ┌──────────┐                                            │
│     │  ./data  │ ←── -v $(pwd)/data:/app/data               │
│     └──────────┘                                            │
│                                                             │
│  3. TMPFS MOUNTS (In-memory, Linux only)                    │
│     RAM                                                     │
│     ┌──────────┐                                            │
│     │  tmpfs   │ ←── --tmpfs /app/temp                      │
│     └──────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

### Docker Volumes (Recommended)

```bash
# ─── CREATING VOLUMES ───

# Create a named volume
docker volume create my-data

# Create with labels
docker volume create --label project=myapp --label env=production app-data

# ─── LISTING VOLUMES ───

docker volume ls

# EXAMPLE OUTPUT:
# DRIVER    VOLUME NAME
# local     my-data
# local     app-data
# local      4a5b6c7d8e9f...  (anonymous volume)

# Filter volumes
docker volume ls --filter "label=project=myapp"
docker volume ls --filter "dangling=true"    # Unused volumes

# ─── INSPECTING VOLUMES ───

docker volume inspect my-data

# Output:
# [
#     {
#         "CreatedAt": "2024-01-15T10:30:00Z",
#         "Driver": "local",
#         "Labels": {},
#         "Mountpoint": "/var/lib/docker/volumes/my-data/_data",
#         "Name": "my-data",
#         "Options": {},
#         "Scope": "local"
#     }
# ]

# ─── USING VOLUMES WITH CONTAINERS ───

# Mount a named volume
docker run -d \
    --name my-database \
    -v my-data:/var/lib/mysql \
    mysql:8.0

# Using the --mount syntax (more explicit, recommended for clarity)
docker run -d \
    --name my-database \
    --mount source=my-data,target=/var/lib/mysql \
    mysql:8.0

# Read-only volume
docker run -d \
    --name my-app \
    -v config-data:/app/config:ro \
    myapp:latest

# ─── REMOVING VOLUMES ───

# Remove a specific volume
docker volume rm my-data

# Remove all unused volumes
docker volume prune

# Force remove
docker volume prune -f
```

### Bind Mounts (Development Favorite)

```bash
# Mount a host directory into a container
docker run -d \
    --name dev-server \
    -v $(pwd)/src:/app/src \
    -v $(pwd)/public:/app/public \
    -p 3000:3000 \
    node:20

# Using --mount syntax (more explicit)
docker run -d \
    --name dev-server \
    --mount type=bind,source=$(pwd)/src,target=/app/src \
    -p 3000:3000 \
    node:20

# Read-only bind mount
docker run -d \
    -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
    -v $(pwd)/html:/usr/share/nginx/html:ro \
    nginx

# Mount a single file
docker run -d \
    -v $(pwd)/custom.conf:/etc/app/config.conf:ro \
    myapp:latest
```

### Practical Volume Examples

```bash
# ─── Example 1: Database with Persistent Storage ───

# Create a volume for database data
docker volume create postgres-data

# Run PostgreSQL with persistent data
docker run -d \
    --name my-postgres \
    -e POSTGRES_PASSWORD=mysecret \
    -e POSTGRES_DB=myapp \
    -v postgres-data:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:16

# Even if we remove and recreate the container, data persists:
docker rm -f my-postgres
docker run -d \
    --name my-postgres-new \
    -e POSTGRES_PASSWORD=mysecret \
    -v postgres-data:/var/lib/postgresql/data \
    -p 5432:5432 \
    postgres:16
# ✅ All data is still there!

# ─── Example 2: Development with Live Code Reload ───

docker run -d \
    --name dev-app \
    -v $(pwd):/app \
    -v /app/node_modules \
    -p 3000:3000 \
    -e NODE_ENV=development \
    node:20 \
    npm run dev

# Explanation:
# -v $(pwd):/app           → Mount code for live editing
# -v /app/node_modules     → Anonymous volume to prevent overwriting
#                             container's node_modules with host's

# ─── Example 3: Sharing Data Between Containers ───

# Create a shared volume
docker volume create shared-data

# Container 1: Writes data
docker run -d \
    --name writer \
    -v shared-data:/data \
    alpine \
    sh -c "while true; do date >> /data/log.txt; sleep 5; done"

# Container 2: Reads data
docker run --rm \
    -v shared-data:/data:ro \
    alpine \
    cat /data/log.txt

# ─── Example 4: Backup a Volume ───

# Backup volume to a tar file
docker run --rm \
    -v postgres-data:/source:ro \
    -v $(pwd):/backup \
    alpine \
    tar czf /backup/postgres-backup.tar.gz -C /source .

# Restore volume from a tar file
docker run --rm \
    -v postgres-data:/target \
    -v $(pwd):/backup:ro \
    alpine \
    sh -c "cd /target && tar xzf /backup/postgres-backup.tar.gz"
```

### When to Use What

```
┌───────────────┬──────────────────────────────────────────────┐
│ Storage Type  │ Best For                                     │
├───────────────┼──────────────────────────────────────────────┤
│ Volumes       │ ✅ Database storage                          │
│               │ ✅ Sharing data between containers           │
│               │ ✅ Production deployments                    │
│               │ ✅ When you don't need direct host access    │
├───────────────┼──────────────────────────────────────────────┤
│ Bind Mounts   │ ✅ Development (live code reloading)         │
│               │ ✅ Configuration files                       │
│               │ ✅ When you need host file access            │
│               │ ⚠️  Not portable between machines            │
├───────────────┼──────────────────────────────────────────────┤
│ tmpfs Mounts  │ ✅ Sensitive data (secrets, temp files)      │
│               │ ✅ Performance-critical temporary data       │
│               │ ⚠️  Data lost when container stops           │
└───────────────┴──────────────────────────────────────────────┘
```

---

## 7. Docker Networking

### Why Docker Networking?

Containers need to communicate with each other (e.g., a web app talking to a database) and with the outside world. Docker networking makes this possible while maintaining isolation.

### Network Types

```
┌─────────────────────────────────────────────────────────────────┐
│                        DOCKER HOST                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  BRIDGE NETWORK (default)                                │   │
│  │  172.17.0.0/16                                           │   │
│  │  ┌────────┐  ┌────────┐  ┌────────┐                     │   │
│  │  │  C1    │  │  C2    │  │  C3    │                     │   │
│  │  │.17.0.2│  │.17.0.3│  │.17.0.4│                     │   │
│  │  └────────┘  └────────┘  └────────┘                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  CUSTOM BRIDGE NETWORK (recommended)                     │   │
│  │  "app-network" — Automatic DNS resolution by name!       │   │
│  │  ┌────────┐  ┌────────┐                                  │   │
│  │  │  web   │──│  db    │  Can reach each other by name!  │   │
│  │  │        │  │        │  web → ping db ✅                │   │
│  │  └────────┘  └────────┘                                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  HOST NETWORK                                            │   │
│  │  Container shares the host's network directly            │   │
│  │  No port mapping needed — container IS the host network  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  NONE NETWORK                                            │   │
│  │  Complete network isolation — no connectivity            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Network Commands

```bash
# ─── LISTING NETWORKS ───

docker network ls

# EXAMPLE OUTPUT:
# NETWORK ID     NAME      DRIVER    SCOPE
# a1b2c3d4e5f6   bridge    bridge    local
# f6e5d4c3b2a1   host      host      local
# 1a2b3c4d5e6f   none      null      local

# ─── CREATING NETWORKS ───

# Create a custom bridge network
docker network create my-network

# Create with specific subnet and gateway
docker network create \
    --driver bridge \
    --subnet 172.20.0.0/16 \
    --gateway 172.20.0.1 \
    --ip-range 172.20.240.0/20 \
    my-custom-network

# Create with labels
docker network create \
    --label project=myapp \
    --label env=development \
    app-network

# ─── INSPECTING NETWORKS ───

docker network inspect my-network

# Shows: subnet, gateway, connected containers, etc.

# ─── CONNECTING CONTAINERS TO NETWORKS ───

# Connect a running container to a network
docker network connect my-network my-container

# Connect with a specific IP address
docker network connect --ip 172.20.0.10 my-network my-container

# Disconnect a container from a network
docker network disconnect my-network my-container

# ─── REMOVING NETWORKS ───

docker network rm my-network

# Remove all unused networks
docker network prune
```

### Practical Networking Example

```bash
# ─── Scenario: Web App + Database ───

# Step 1: Create a custom network
docker network create webapp-network

# Step 2: Run a database on the network
docker run -d \
    --name database \
    --network webapp-network \
    -e POSTGRES_PASSWORD=secret \
    -e POSTGRES_DB=myapp \
    -v db-data:/var/lib/postgresql/data \
    postgres:16

# Step 3: Run a web application on the same network
docker run -d \
    --name webapp \
    --network webapp-network \
    -e DATABASE_URL=postgresql://postgres:secret@database:5432/myapp \
    -p 8080:8080 \
    mywebapp:latest

# ✅ "database" in the DATABASE_URL works because Docker's built-in
# DNS resolves container names on custom networks!

# Step 4: Verify connectivity
docker exec webapp ping database -c 3
# PING database (172.20.0.2): 56 data bytes
# 64 bytes from 172.20.0.2: seq=0 ttl=64 time=0.089 ms

# Step 5: See which containers are on the network
docker network inspect webapp-network \
    --format '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
# database 172.20.0.2/16
# webapp 172.20.0.3/16
```

### Default Bridge vs Custom Bridge

```
DEFAULT BRIDGE                          CUSTOM BRIDGE
─────────────────                       ─────────────────
❌ No automatic DNS                     ✅ Automatic DNS resolution
   (must use --link or IP)                (use container names)
   
❌ All containers on same network       ✅ Network isolation between
   by default                             different app stacks

❌ Can't connect/disconnect while       ✅ Connect/disconnect containers
   running (without restart)              on the fly

❌ Shared between all containers        ✅ Scoped to your application
```

### Multi-Network Setup

```bash
# Scenario: Frontend can talk to Backend, Backend can talk to Database
# But Frontend CANNOT talk directly to Database

# Create two networks
docker network create frontend-network
docker network create backend-network

# Database — only on backend network
docker run -d \
    --name db \
    --network backend-network \
    -e POSTGRES_PASSWORD=secret \
    postgres:16

# Backend API — on BOTH networks (bridge between frontend and database)
docker run -d \
    --name api \
    --network backend-network \
    -e DB_HOST=db \
    myapi:latest

# Connect API to frontend network too
docker network connect frontend-network api

# Frontend — only on frontend network
docker run -d \
    --name frontend \
    --network frontend-network \
    -e API_URL=http://api:3000 \
    -p 80:80 \
    myfrontend:latest

# Result:
# frontend → api  ✅ (both on frontend-network)
# api → db        ✅ (both on backend-network)
# frontend → db   ❌ (different networks, no direct access!)
```

```
┌───────────────────────────┐  ┌───────────────────────────┐
│   frontend-network        │  │   backend-network         │
│                           │  │                           │
│  ┌──────────┐  ┌────────┐│  │┌────────┐  ┌──────────┐  │
│  │ frontend │──│  api   ││──││  api   │──│    db    │  │
│  └──────────┘  └────────┘│  │└────────┘  └──────────┘  │
│                           │  │                           │
└───────────────────────────┘  └───────────────────────────┘
```

---

## 8. Docker Compose

### What Is Docker Compose?

Docker Compose is a tool for defining and running **multi-container applications** using a single YAML file. Instead of running long `docker run` commands for each container, you define everything in `docker-compose.yml` and manage it with simple commands.

```
WITHOUT Docker Compose:                WITH Docker Compose:
                                       
$ docker network create myapp          $ docker compose up -d
$ docker volume create db-data         
$ docker run -d \                      That's it! ✅
    --name db \                        
    --network myapp \                  Everything is defined in
    -v db-data:/var/lib/mysql \        docker-compose.yml
    -e MYSQL_ROOT_PASSWORD=... \       
    mysql:8.0                          
$ docker run -d \                      
    --name app \                       
    --network myapp \                  
    -p 8080:80 \                       
    -e DB_HOST=db \                    
    myapp:latest                       
$ docker run -d \                      
    --name redis \                     
    --network myapp \                  
    redis:alpine                       
```

### Docker Compose File Structure

```yaml
# docker-compose.yml

# Version is optional in modern Docker Compose (v2+)
# but you may see it in older files:
# version: "3.8"

services:         # Define your containers
  web:            # Service name (also becomes the DNS hostname)
    ...
  database:
    ...
  cache:
    ...

volumes:          # Define named volumes
  db-data:
  cache-data:

networks:         # Define custom networks
  frontend:
  backend:

secrets:          # Define secrets (for sensitive data)
  db-password:
    file: ./secrets/db-password.txt

configs:          # Define configs
  nginx-config:
    file: ./nginx.conf
```

### Complete Docker Compose Example

**Project: A full-stack web application with React frontend, Node.js API, PostgreSQL database, and Redis cache.**

```yaml
# docker-compose.yml

services:
  # ══════════════════════════════════════
  # FRONTEND — React Application
  # ══════════════════════════════════════
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - REACT_APP_API_URL=http://localhost:3000
    container_name: myapp-frontend
    ports:
      - "80:80"
    depends_on:
      - api
    networks:
      - frontend-network
    restart: unless-stopped

  # ══════════════════════════════════════
  # API — Node.js Backend
  # ══════════════════════════════════════
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
      target: production          # Multi-stage build target
    container_name: myapp-api
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=database
      - DB_PORT=5432
      - DB_NAME=myapp
      - DB_USER=postgres
      - DB_PASSWORD_FILE=/run/secrets/db-password
      - REDIS_URL=redis://cache:6379
    env_file:
      - ./backend/.env           # Load additional env vars from file
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_started
    volumes:
      - api-logs:/app/logs
    networks:
      - frontend-network
      - backend-network
    secrets:
      - db-password
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 128M

  # ══════════════════════════════════════
  # DATABASE — PostgreSQL
  # ══════════════════════════════════════
  database:
    image: postgres:16-alpine
    container_name: myapp-db
    ports:
      - "5432:5432"              # Expose for local development tools
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD_FILE=/run/secrets/db-password
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - backend-network
    secrets:
      - db-password
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ══════════════════════════════════════
  # CACHE — Redis
  # ══════════════════════════════════════
  cache:
    image: redis:7-alpine
    container_name: myapp-cache
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --maxmemory 256mb
    volumes:
      - cache-data:/data
    networks:
      - backend-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

  # ══════════════════════════════════════
  # ADMINER — Database Web UI (dev only)
  # ══════════════════════════════════════
  adminer:
    image: adminer:latest
    container_name: myapp-adminer
    ports:
      - "8080:8080"
    networks:
      - backend-network
    depends_on:
      - database
    profiles:
      - debug                    # Only starts with --profile debug

# ══════════════════════════════════════
# VOLUMES
# ══════════════════════════════════════
volumes:
  db-data:
    name: myapp-db-data
  cache-data:
    name: myapp-cache-data
  api-logs:
    name: myapp-api-logs

# ══════════════════════════════════════
# NETWORKS
# ══════════════════════════════════════
networks:
  frontend-network:
    name: myapp-frontend
    driver: bridge
  backend-network:
    name: myapp-backend
    driver: bridge

# ══════════════════════════════════════
# SECRETS
# ══════════════════════════════════════
secrets:
  db-password:
    file: ./secrets/db-password.txt
```

### Docker Compose Commands

```bash
# ─── STARTING SERVICES ───

# Start all services in the background
docker compose up -d

# Start specific services only
docker compose up -d database cache

# Start with build (rebuild images)
docker compose up -d --build

# Start with a specific compose file
docker compose -f docker-compose.prod.yml up -d

# Start with a profile
docker compose --profile debug up -d

# Scale a service (run multiple instances)
docker compose up -d --scale api=3

# ─── STOPPING SERVICES ───

# Stop all services
docker compose down

# Stop and remove volumes too
docker compose down -v

# Stop and remove images too
docker compose down --rmi all

# Stop specific services
docker compose stop api frontend

# ─── VIEWING STATUS ───

# List running services
docker compose ps

# EXAMPLE OUTPUT:
# NAME              IMAGE            STATUS                   PORTS
# myapp-api         myapp-api        Up 2 hours (healthy)     0.0.0.0:3000->3000/tcp
# myapp-db          postgres:16      Up 2 hours (healthy)     0.0.0.0:5432->5432/tcp
# myapp-cache       redis:7-alpine   Up 2 hours (healthy)     0.0.0.0:6379->6379/tcp
# myapp-frontend    myapp-frontend   Up 2 hours               0.0.0.0:80->80/tcp

# View logs
docker compose logs

# Follow logs for specific services
docker compose logs -f api database

# Show last 100 lines
docker compose logs --tail 100 api

# ─── MANAGING SERVICES ───

# Restart services
docker compose restart
docker compose restart api

# Rebuild and restart a service
docker compose up -d --build api

# Execute a command in a service
docker compose exec api bash
docker compose exec database psql -U postgres -d myapp

# Run a one-off command (creates a new container)
docker compose run --rm api npm test
docker compose run --rm api npm run migrate

# View resource usage
docker compose top

# ─── BUILDING ───

# Build all images
docker compose build

# Build without cache
docker compose build --no-cache

# Build specific service
docker compose build api

# Pull latest images
docker compose pull

# ─── CONFIGURATION ───

# Validate and view the compose file
docker compose config

# Show the resolved configuration
docker compose config --services   # List service names
docker compose config --volumes    # List volume names
```

### Development vs Production Compose Files

**docker-compose.yml** (base):
```yaml
services:
  api:
    build: ./backend
    environment:
      - DB_HOST=database
    depends_on:
      - database
    networks:
      - app-network

  database:
    image: postgres:16-alpine
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network

volumes:
  db-data:

networks:
  app-network:
```

**docker-compose.override.yml** (automatically loaded, for development):
```yaml
services:
  api:
    build:
      context: ./backend
      target: development
    ports:
      - "3000:3000"
      - "9229:9229"          # Debug port
    volumes:
      - ./backend/src:/app/src   # Live code reload
    environment:
      - NODE_ENV=development
      - DEBUG=true
    command: npm run dev

  database:
    ports:
      - "5432:5432"          # Expose for local tools
    environment:
      - POSTGRES_PASSWORD=devpassword
```

**docker-compose.prod.yml** (for production):
```yaml
services:
  api:
    build:
      context: ./backend
      target: production
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    restart: always
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: "0.5"
          memory: 256M

  database:
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db-password
    restart: always
    # No exposed ports in production!
```

**Usage:**
```bash
# Development (uses docker-compose.yml + docker-compose.override.yml)
docker compose up -d

# Production (uses docker-compose.yml + docker-compose.prod.yml)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Using Environment Variables in Compose

```yaml
# docker-compose.yml
services:
  api:
    image: myapp:${APP_VERSION:-latest}     # Default to 'latest'
    ports:
      - "${API_PORT:-3000}:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
```

**.env** file (automatically loaded):
```bash
APP_VERSION=2.1.0
API_PORT=8080
DATABASE_URL=postgresql://user:pass@db:5432/myapp
```

```bash
# Override with shell environment variables
APP_VERSION=3.0.0 docker compose up -d

# Or export them
export APP_VERSION=3.0.0
docker compose up -d
```

---

## 9. Docker Registry

### What Is a Docker Registry?

A registry is a **storage and distribution system for Docker images**. Think of it as an "app store" for Docker images.

```
┌──────────────────────────────────────────────────────────────┐
│                     DOCKER REGISTRIES                         │
│                                                               │
│  PUBLIC                        PRIVATE                        │
│  ┌─────────────────┐          ┌──────────────────────┐       │
│  │  Docker Hub     │          │  AWS ECR             │       │
│  │  (hub.docker.com│          │  Google GCR/Artifact │       │
│  │   default)      │          │  Azure ACR           │       │
│  └─────────────────┘          │  GitHub GHCR         │       │
│                               │  Self-hosted Registry│       │
│                               └──────────────────────┘       │
└──────────────────────────────────────────────────────────────┘
```

### Working with Docker Hub

```bash
# ─── LOGIN ───

# Login to Docker Hub
docker login
# Enter username and password when prompted

# Login to a specific registry
docker login registry.example.com
docker login ghcr.io

# ─── PUSH (Upload) ───

# Step 1: Tag your image with your Docker Hub username
docker tag myapp:latest yourusername/myapp:1.0
docker tag myapp:latest yourusername/myapp:latest

# Step 2: Push to Docker Hub
docker push yourusername/myapp:1.0
docker push yourusername/myapp:latest

# Push all tags
docker push yourusername/myapp --all-tags

# ─── PULL (Download) ───

docker pull yourusername/myapp:1.0

# ─── SEARCH ───

docker search nginx
docker search --filter "is-official=true" nginx

# ─── LOGOUT ───

docker logout
docker logout registry.example.com
```

### Running Your Own Private Registry

```bash
# Run a local registry
docker run -d \
    --name registry \
    -p 5000:5000 \
    -v registry-data:/var/lib/registry \
    --restart always \
    registry:2

# Tag and push to local registry
docker tag myapp:latest localhost:5000/myapp:1.0
docker push localhost:5000/myapp:1.0

# Pull from local registry
docker pull localhost:5000/myapp:1.0

# List images in local registry (API)
curl http://localhost:5000/v2/_catalog
# Output: {"repositories":["myapp"]}

# List tags for an image
curl http://localhost:5000/v2/myapp/tags/list
# Output: {"name":"myapp","tags":["1.0"]}
```

### Push to GitHub Container Registry

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Tag for GHCR
docker tag myapp:latest ghcr.io/yourusername/myapp:1.0

# Push
docker push ghcr.io/yourusername/myapp:1.0
```

---

## 10. Docker Security Best Practices

### Image Security

```dockerfile
# ✅ 1. Use official and verified base images
FROM python:3.11-slim          # Official Python image
# ❌ FROM random-user/python   # Unverified image

# ✅ 2. Use specific tags, never :latest in production
FROM node:20.10.0-alpine
# ❌ FROM node:latest

# ✅ 3. Use minimal base images
FROM python:3.11-slim     # ~150MB (good)
FROM python:3.11-alpine   # ~50MB  (better, but may have compatibility issues)
# ❌ FROM python:3.11       # ~1GB  (includes lots of unnecessary tools)
# ❌ FROM ubuntu:22.04       # Then install Python manually

# ✅ 4. Run as non-root user
RUN groupadd -r appgroup && \
    useradd -r -g appgroup -d /app -s /sbin/nologin appuser
WORKDIR /app
COPY --chown=appuser:appgroup . .
USER appuser

# ✅ 5. Don't store secrets in images
# ❌ ENV API_KEY=super-secret-key-12345
# ❌ COPY secrets.json /app/secrets.json
# ✅ Use Docker secrets, environment variables at runtime, or vault
```

### Container Security

```bash
# ✅ 6. Run with read-only filesystem
docker run --read-only \
    --tmpfs /tmp \
    --tmpfs /var/run \
    myapp:latest

# ✅ 7. Drop all capabilities and add only what's needed
docker run \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    myapp:latest

# ✅ 8. Set memory and CPU limits
docker run \
    --memory="256m" \
    --cpus="0.5" \
    --pids-limit 100 \
    myapp:latest

# ✅ 9. Use security options
docker run \
    --security-opt no-new-privileges:true \
    myapp:latest

# ✅ 10. Scan images for vulnerabilities
docker scout cves myapp:latest
# Or use tools like Trivy:
# trivy image myapp:latest
```

### Security Checklist

```
IMAGE BUILDING:
  □ Use official/verified base images
  □ Pin image versions (no :latest in production)
  □ Use multi-stage builds
  □ Don't install unnecessary packages
  □ Scan images for vulnerabilities
  □ Use .dockerignore to exclude sensitive files
  □ Don't hardcode secrets

RUNTIME:
  □ Run as non-root user
  □ Use read-only filesystems where possible
  □ Set resource limits (memory, CPU, PIDs)
  □ Drop unnecessary Linux capabilities
  □ Use custom networks (not default bridge)
  □ Don't expose unnecessary ports
  □ Enable Docker Content Trust (image signing)
  □ Keep Docker engine updated
```

---

## 11. Docker Orchestration

### What Is Container Orchestration?

When you have many containers running across multiple servers, you need a tool to manage them automatically. This is **orchestration** — it handles deployment, scaling, networking, and self-healing.

```
SINGLE HOST                          ORCHESTRATED CLUSTER
┌─────────────┐                     ┌──────────┐ ┌──────────┐ ┌──────────┐
│   Docker    │                     │  Node 1  │ │  Node 2  │ │  Node 3  │
│ ┌───┐ ┌───┐│                     │ ┌──┐┌──┐ │ │ ┌──┐┌──┐ │ │ ┌──┐┌──┐│
│ │ C1│ │ C2││                     │ │C1││C2│ │ │ │C3││C4│ │ │ │C5││C6││
│ └───┘ └───┘│                     │ └──┘└──┘ │ │ └──┘└──┘ │ │ └──┘└──┘│
│ ┌───┐      │                     └──────────┘ └──────────┘ └──────────┘
│ │ C3│      │                           ▲            ▲            ▲
│ └───┘      │                           └────────────┼────────────┘
└─────────────┘                                       │
                                              ┌───────────────┐
Good for development                          │ ORCHESTRATOR  │
                                              │ (Swarm / K8s) │
                                              └───────────────┘
                                          Manages everything automatically
```

### Docker Swarm (Built-in Orchestration)

Docker Swarm is Docker's **native clustering and orchestration** solution. It's simpler than Kubernetes and built right into Docker.

```bash
# ─── INITIALIZING A SWARM ───

# Initialize the current machine as a Swarm manager
docker swarm init
# Output includes a join token for worker nodes

# Initialize with a specific advertise address
docker swarm init --advertise-addr 192.168.1.100

# Get the join token for workers
docker swarm join-token worker

# Get the join token for managers
docker swarm join-token manager

# ─── JOINING THE SWARM (run on other machines) ───

# Join as a worker
docker swarm join --token SWMTKN-1-xxx 192.168.1.100:2377

# ─── MANAGING NODES ───

# List nodes in the swarm
docker node ls

# EXAMPLE OUTPUT:
# ID           HOSTNAME    STATUS   AVAILABILITY   MANAGER STATUS
# abc123 *     manager1    Ready    Active         Leader
# def456       worker1     Ready    Active         
# ghi789       worker2     Ready    Active         

# Inspect a node
docker node inspect worker1

# Drain a node (stop scheduling new tasks on it)
docker node update --availability drain worker1

# Make it active again
docker node update --availability active worker1

# Promote a worker to manager
docker node promote worker1

# Demote a manager to worker
docker node demote worker1

# ─── LEAVING THE SWARM ───

# Leave from a worker
docker swarm leave

# Leave from a manager (force)
docker swarm leave --force
```

### Docker Services (Swarm Mode)

A **service** is the Swarm equivalent of `docker run` — but it manages replication, rolling updates, and self-healing across the cluster.

```bash
# ─── CREATING SERVICES ───

# Create a simple service
docker service create \
    --name web \
    --replicas 3 \
    -p 8080:80 \
    nginx:alpine

# Create with more options
docker service create \
    --name api \
    --replicas 5 \
    --publish 3000:3000 \
    --env NODE_ENV=production \
    --env DB_HOST=database \
    --mount type=volume,source=api-data,target=/app/data \
    --limit-cpu 0.5 \
    --limit-memory 256M \
    --restart-condition on-failure \
    --restart-max-attempts 3 \
    --update-parallelism 2 \
    --update-delay 10s \
    --health-cmd "curl -f http://localhost:3000/health" \
    --health-interval 30s \
    myapi:latest

# ─── MANAGING SERVICES ───

# List services
docker service ls

# View detailed service info
docker service inspect web --pretty

# View tasks (individual containers) of a service
docker service ps web

# View logs
docker service logs web
docker service logs -f web

# ─── SCALING ───

# Scale to 10 replicas
docker service scale web=10

# Scale multiple services
docker service scale web=5 api=3 worker=10

# ─── UPDATING ───

# Update the image
docker service update --image nginx:1.25 web

# Rolling update configuration
docker service update \
    --update-parallelism 2 \
    --update-delay 30s \
    --update-failure-action rollback \
    --image myapi:2.0 \
    api

# Rollback to previous version
docker service rollback api

# Update environment variables
docker service update --env-add NEW_VAR=value web
docker service update --env-rm OLD_VAR web

# ─── REMOVING ───

docker service rm web
```

### Docker Stack (Compose for Swarm)

Docker Stack lets you use Docker Compose files to deploy to a Swarm cluster.

```yaml
# docker-stack.yml
services:
  web:
    image: nginx:alpine
    ports:
      - "80:80"
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      rollback_config:
        parallelism: 1
        delay: 5s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          cpus: "0.5"
          memory: 128M
    networks:
      - webnet

  api:
    image: myapi:latest
    deploy:
      replicas: 5
      placement:
        constraints:
          - node.labels.type == api
    networks:
      - webnet
      - backend

  database:
    image: postgres:16
    volumes:
      - db-data:/var/lib/postgresql/data
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
    networks:
      - backend

volumes:
  db-data:

networks:
  webnet:
  backend:
```

```bash
# Deploy a stack
docker stack deploy -c docker-stack.yml myapp

# List stacks
docker stack ls

# List services in a stack
docker stack services myapp

# List tasks in a stack
docker stack ps myapp

# Remove a stack
docker stack rm myapp
```

### Kubernetes Overview (Brief)

While Docker Swarm is simpler, **Kubernetes (K8s)** is the industry standard for container orchestration at scale.

```
DOCKER SWARM vs KUBERNETES

Docker Swarm:                      Kubernetes:
✅ Simple to set up               ✅ Industry standard
✅ Built into Docker              ✅ Massive ecosystem
✅ Good for small/medium          ✅ Advanced scheduling
✅ Uses Docker Compose files      ✅ Auto-scaling
                                  ✅ Service mesh support
❌ Limited auto-scaling           
❌ Smaller community              ❌ Steeper learning curve
❌ Fewer advanced features        ❌ More complex setup
                                  ❌ More resource overhead

RECOMMENDATION:
• Small teams / simple apps → Docker Swarm
• Large teams / complex apps / enterprise → Kubernetes
```

---

## 12. Troubleshooting & Debugging

### Common Issues and Solutions

```bash
# ─── ISSUE: Container exits immediately ───

# Check exit code and logs
docker ps -a                              # See the exit code
docker logs <container>                   # See what happened

# Common exit codes:
# 0   = Normal exit (CMD finished)
# 1   = Application error
# 137 = Killed (OOM or docker kill) — SIGKILL
# 139 = Segmentation fault
# 143 = Graceful termination — SIGTERM

# Run interactively to debug
docker run -it myapp:latest bash          # Override CMD with bash
docker run -it myapp:latest sh            # For Alpine images

# ─── ISSUE: Port already in use ───

# Find what's using the port
lsof -i :8080                            # macOS/Linux
netstat -tlnp | grep 8080                # Linux

# Use a different port
docker run -p 8081:80 nginx              # Map to 8081 instead

# ─── ISSUE: Cannot connect to Docker daemon ───

# Check if Docker is running
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# Check permissions
sudo usermod -aG docker $USER
# Then log out and back in

# ─── ISSUE: Image build fails ───

# Build with verbose output
docker build --progress=plain --no-cache -t myapp .

# Check intermediate layers
docker build -t myapp . 2>&1 | tee build.log

# ─── ISSUE: Container can't reach another container ───

# Check if containers are on the same network
docker network inspect <network-name>

# Test connectivity
docker exec container1 ping container2
docker exec container1 nslookup container2

# Check if DNS resolution works
docker exec container1 cat /etc/resolv.conf
```

### Debugging Commands

```bash
# ─── INSPECT EVERYTHING ───

# Container details
docker inspect <container>

# Get specific fields
docker inspect --format '{{.State.Status}}' <container>
docker inspect --format '{{.State.ExitCode}}' <container>
docker inspect --format '{{.NetworkSettings.IPAddress}}' <container>
docker inspect --format '{{json .Config.Env}}' <container> | jq .

# ─── REAL-TIME MONITORING ───

# Watch all container resource usage
docker stats

# Watch specific containers
docker stats container1 container2

# Watch events (container start/stop/die/etc.)
docker events
docker events --filter 'type=container'
docker events --filter 'event=die'
docker events --since '1h'

# ─── FILESYSTEM DEBUGGING ───

# See what changed in a container's filesystem
docker diff <container>
# A = Added, C = Changed, D = Deleted

# Export a container's filesystem for analysis
docker export <container> | tar tf -

# ─── NETWORK DEBUGGING ───

# Check port mappings
docker port <container>

# Inspect network
docker network inspect bridge

# Check iptables rules (Linux)
sudo iptables -L -n -t nat | grep DOCKER

# ─── LOG DEBUGGING ───

# View all logs
docker logs <container>

# Follow with timestamps
docker logs -f -t <container>

# Show logs since a timestamp
docker logs --since "2024-01-15T10:00:00" <container>

# Limit output
docker logs --tail 200 <container>
```

### Cleanup Commands

```bash
# ─── SELECTIVE CLEANUP ───

# Remove stopped containers
docker container prune

# Remove unused images
docker image prune        # Only dangling (untagged) images
docker image prune -a     # All unused images

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# ─── NUCLEAR CLEANUP (removes everything unused) ───

docker system prune

# Remove EVERYTHING including volumes
docker system prune -a --volumes

# ─── CHECK DISK USAGE ───

docker system df

# EXAMPLE OUTPUT:
# TYPE            TOTAL   ACTIVE   SIZE      RECLAIMABLE
# Images          15      5        5.234GB   3.112GB (59%)
# Containers      8       3        256.5MB   128.3MB (50%)
# Local Volumes   10      4        1.234GB   567.8MB (46%)
# Build Cache     25      0        2.345GB   2.345GB

# Detailed disk usage
docker system df -v
```

---

## 13. Real-World Project Example

Let's build a complete application stack from scratch.

### Project: Blog Application

**Architecture:**
```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   NGINX     │────▶│  Node.js API │────▶│  PostgreSQL  │
│   (Proxy)   │     │   (Backend)  │     │  (Database)  │
│   Port 80   │     │   Port 3000  │     │  Port 5432   │
└─────────────┘     └──────┬───────┘     └──────────────┘
                           │
                    ┌──────▼───────┐
                    │    Redis     │
                    │   (Cache)    │
                    │  Port 6379   │
                    └──────────────┘
```

**Directory structure:**
```
blog-app/
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env
├── .dockerignore
├── nginx/
│   └── default.conf
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── src/
│   │   └── server.js
│   └── .dockerignore
├── database/
│   └── init.sql
└── secrets/
    └── db-password.txt
```

**backend/Dockerfile:**
```dockerfile
# ══════════════════════════════════════
# Stage 1: Development
# ══════════════════════════════════════
FROM node:20-alpine AS development

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]

# ══════════════════════════════════════
# Stage 2: Build
# ══════════════════════════════════════
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# ══════════════════════════════════════
# Stage 3: Production
# ══════════════════════════════════════
FROM node:20-alpine AS production

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app .

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
```

**nginx/default.conf:**
```nginx
upstream api {
    server api:3000;
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    location /health {
        access_log off;
        return 200 "OK";
    }
}
```

**docker-compose.yml:**
```yaml
services:
  nginx:
    image: nginx:alpine
    container_name: blog-nginx
    ports:
      - "${APP_PORT:-80}:80"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      api:
        condition: service_healthy
    networks:
      - frontend
    restart: unless-stopped

  api:
    build:
      context: ./backend
      target: ${BUILD_TARGET:-production}
    container_name: blog-api
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - DB_HOST=database
      - DB_PORT=5432
      - DB_NAME=${DB_NAME:-blogdb}
      - DB_USER=${DB_USER:-postgres}
      - DB_PASSWORD=${DB_PASSWORD:-secret}
      - REDIS_URL=redis://cache:6379
    depends_on:
      database:
        condition: service_healthy
      cache:
        condition: service_healthy
    networks:
      - frontend
      - backend
    restart: unless-stopped

  database:
    image: postgres:16-alpine
    container_name: blog-db
    environment:
      - POSTGRES_DB=${DB_NAME:-blogdb}
      - POSTGRES_USER=${DB_USER:-postgres}
      - POSTGRES_PASSWORD=${DB_PASSWORD:-secret}
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    container_name: blog-cache
    command: redis-server --appendonly yes
    volumes:
      - cache-data:/data
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  db-data:
  cache-data:

networks:
  frontend:
  backend:
```

**.env:**
```bash
# Application
NODE_ENV=production
APP_PORT=80
BUILD_TARGET=production

# Database
DB_NAME=blogdb
DB_USER=postgres
DB_PASSWORD=change-me-in-production
```

**Running the project:**
```bash
# Development
NODE_ENV=development BUILD_TARGET=development docker compose up -d

# Production
docker compose up -d --build

# View status
docker compose ps

# View all logs
docker compose logs -f

# Run database migrations
docker compose exec api npm run migrate

# Access database shell
docker compose exec database psql -U postgres -d blogdb

# Backup database
docker compose exec database pg_dump -U postgres blogdb > backup.sql

# Scale API
docker compose up -d --scale api=3

# Stop everything
docker compose down

# Stop and clean everything
docker compose down -v --rmi all
```

---

## 14. Quick Reference Cheat Sheet

### Container Lifecycle

```bash
docker create <image>                    # Create (don't start)
docker start <container>                 # Start a stopped container
docker run <image>                       # Create + Start
docker run -d <image>                    # Create + Start (background)
docker run -it <image> bash              # Create + Start (interactive)
docker stop <container>                  # Graceful stop (SIGTERM)
docker kill <container>                  # Force stop (SIGKILL)
docker restart <container>               # Stop + Start
docker pause <container>                 # Freeze processes
docker unpause <container>               # Unfreeze processes
docker rm <container>                    # Remove stopped container
docker rm -f <container>                 # Force remove (even running)
```

### Container Inspection

```bash
docker ps                                # List running containers
docker ps -a                             # List all containers
docker logs <container>                  # View logs
docker logs -f <container>               # Follow logs
docker exec -it <container> bash         # Open shell
docker inspect <container>               # Full details (JSON)
docker stats                             # Resource usage
docker top <container>                   # Running processes
docker port <container>                  # Port mappings
docker diff <container>                  # Filesystem changes
docker cp <src> <container>:<dest>       # Copy files in
docker cp <container>:<src> <dest>       # Copy files out
```

### Image Management

```bash
docker images                            # List images
docker pull <image>:<tag>                # Download image
docker push <image>:<tag>                # Upload image
docker build -t <name>:<tag> .           # Build from Dockerfile
docker tag <image> <new-name>:<tag>      # Tag an image
docker rmi <image>                       # Remove image
docker image prune                       # Remove unused images
docker save <image> > file.tar          # Export to file
docker load < file.tar                   # Import from file
docker history <image>                   # Show layers
```

### Volume Management

```bash
docker volume create <name>              # Create volume
docker volume ls                         # List volumes
docker volume inspect <name>             # Volume details
docker volume rm <name>                  # Remove volume
docker volume prune                      # Remove unused volumes
# Usage: docker run -v <volume>:/path <image>
# Usage: docker run -v /host/path:/container/path <image>
```

### Network Management

```bash
docker network create <name>             # Create network
docker network ls                        # List networks
docker network inspect <name>            # Network details
docker network connect <net> <container> # Connect container
docker network disconnect <net> <cont>   # Disconnect container
docker network rm <name>                 # Remove network
docker network prune                     # Remove unused networks
```

### Docker Compose

```bash
docker compose up -d                     # Start all services
docker compose down                      # Stop all services
docker compose down -v                   # Stop + remove volumes
docker compose ps                        # List services
docker compose logs -f                   # Follow all logs
docker compose logs -f <service>         # Follow service logs
docker compose exec <service> bash       # Shell into service
docker compose build                     # Build all images
docker compose pull                      # Pull all images
docker compose restart                   # Restart all services
docker compose stop                      # Stop (don't remove)
docker compose run --rm <svc> <cmd>      # Run one-off command
docker compose config                    # Validate config
```

### System & Cleanup

```bash
docker system df                         # Disk usage
docker system prune                      # Clean unused resources
docker system prune -a --volumes         # Clean EVERYTHING unused
docker info                              # System information
docker version                           # Version details
docker events                            # Real-time events
```

### Essential `docker run` Flags

```
FLAG                          PURPOSE
──────────────────────────    ──────────────────────────────────────
-d, --detach                  Run in background
-it                           Interactive with terminal
--name <name>                 Assign a name
-p <host>:<container>         Map ports
-v <host>:<container>         Mount volume/bind
-e KEY=VALUE                  Set environment variable
--env-file <file>             Load env vars from file
--network <name>              Connect to network
--rm                          Remove after exit
--restart <policy>            Restart policy (no/always/on-failure)
--memory <limit>              Memory limit (e.g., 512m, 2g)
--cpus <limit>                CPU limit (e.g., 0.5, 2)
-w, --workdir <path>          Working directory inside container
-u, --user <user>             Run as specific user
--read-only                   Read-only filesystem
--health-cmd <cmd>            Health check command
```

---

## Final Tips for Your Docker Journey

```
BEGINNER → Start here:
  1. Learn to run containers (docker run)
  2. Write basic Dockerfiles
  3. Use Docker Compose for multi-container apps
  4. Understand volumes for data persistence

INTERMEDIATE → Level up:
  5. Master multi-stage builds
  6. Implement proper networking
  7. Follow security best practices
  8. Set up CI/CD pipelines with Docker

ADVANCED → Go further:
  9.  Container orchestration (Swarm/Kubernetes)
  10. Custom networking and service mesh
  11. Performance optimization
  12. Production hardening and monitoring
```

---

> **Remember:** The best way to learn Docker is by doing. Start with a simple project, containerize it, and gradually add complexity. Every mistake is a learning opportunity. Happy containerizing! 🐳