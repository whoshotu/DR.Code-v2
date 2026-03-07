# DR.CODE-v2

AI-powered code quality analysis with automated fix suggestions and GitHub PR integration.
[![Test](https://github.com/whoshotu/DR.Code-v2/actions/workflows/test.yml/badge.svg)](https://github.com/whoshotu/DR.Code-v2/actions/workflows/test.yml)
[![Build](https://github.com/whoshotu/DR.Code-v2/actions/workflows/build.yml/badge.svg)](https://github.com/whoshotu/DR.Code-v2/actions/workflows/build.yml)
## Choose Your Setup Type

| # | Setup Type | Description |
|---|------------|-------------|
| [1](#1-easy-setup) | Easy Setup | One-command script (recommended) |
| [2](#2-local-development) | Local Development | Run on your machine (Mac/Windows/Linux) |
| [3](#3-docker-compose) | Docker Compose | All-in-one container setup |
| [4](#4-pre-built-docker-images) | Pre-built Images | Pull from GHCR (fastest) |
| [5](#5-cloud-deployment) | Cloud Deployment | Deploy to any container hosting service |
| [6](#6-webhook-testing) | Webhook Testing | Test GitHub PR webhooks locally |

Jump to: [`#1`](#1-easy-setup) [`#2`](#2-local-development) [`#3`](#3-docker-compose) [`#4`](#4-pre-built-docker-images) [`#5`](#5-cloud-deployment) [`#6`](#6-webhook-testing)

---

## Quick Start (Easy Setup)

```bash
# 1. Clone the repo
git clone https://github.com/whoshotu/DR.Code-v2.git
cd DR.Code-v2

# 2. Run the easy setup script
./setup.sh

# 3. That's it! Access at:
#    - Frontend: http://localhost:3001
#    - Backend:  http://localhost:8002
```

Or use the Makefile for common commands:

```bash
make install    # Install dependencies
make docker-up  # Start services
make docker-down # Stop services
make test       # Run tests
make open       # Open frontend in browser
```

The setup script will guide you through:
- MongoDB Atlas setup (free, no card required)
- AI model choice: Ollama, LM Studio, or OpenAI
- Optional GitHub integration

---

## Quick Start (Local Development)

```bash
# 1. Clone the repo
git clone https://github.com/whoshotu/DR.Code-v2.git
cd DR.CODE-v2

# 2. Backend setup (using venv to avoid system Python issues)
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Edit with your values
uvicorn server:app --port 8002 --reload

# 3. Frontend setup (new terminal)
cd ../frontend
cp .env.example .env  # Set REACT_APP_BACKEND_URL=http://localhost:8002
npm install --legacy-peer-deps
PORT=3001 npm start
```

Or use the Makefile:
```bash
make install  # Install all dependencies
make dev      # Start dev servers
```

Visit: http://localhost:3001

---

## Prerequisites

### Easy Setup (Recommended)
- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- MongoDB Atlas account (free tier - no card)
- Ollama, LM Studio, or OpenAI (optional)

### All Setups

| Requirement | Purpose |
|-------------|---------|
| **MongoDB Atlas** | Database (free tier works) |
| **Ollama** | AI for code analysis |
| **GitHub PAT** | For PR comments (optional, for webhook feature) |

### Local Development

- Python 3.10+
- Node.js 18+
- Ollama installed locally

### Docker Compose

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Docker Compose

### Cloud Deployment

- Docker image build capability
- Cloud provider account

### Webhook Testing

- ngrok or similar tunneling tool

---

## 1. Easy Setup (Recommended)

Run the automated setup script:

```bash
./setup.sh
```

The script will:
1. Check Docker is installed
2. Guide you to create a free MongoDB Atlas account
3. Ask to install Ollama (or use LM Studio/OpenAI)
4. Optionally add GitHub token for PR reviews
5. Create `.env` and start containers

### Manual Setup (without setup.sh)

If you prefer manual setup:

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` with your values:
```bash
MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/?appName=drcode
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_MODEL=codellama
```

3. Start Docker:
```bash
docker-compose up -d
```

---

## 2. Local Development

### Environment Variables

Create `backend/.env`:

```bash
# Required
MONGO_URL=mongodb+srv://<username>:<password>@cluster.mongodb.net/drcode
DB_NAME=drcode

# Required for AI analysis
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b

# Frontend (for CORS)
CORS_ORIGINS=http://localhost:3001

# Optional: GitHub Integration
# GITHUB_TOKEN=ghp_xxxxx
# GITHUB_WEBHOOK_SECRET=xxxxx
```

Create `frontend/.env`:

```bash
REACT_APP_BACKEND_URL=http://localhost:8002
```

### Running the Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn server:app --port 8002 --reload
```

### Running the Frontend

```bash
cd frontend
npm install
PORT=3001 npm start
```

### Verifying It Works

1. Open http://localhost:3001
2. Go to Settings → Configure Ollama (base URL + model)
3. Test with Analyze tab

---

## 3. Docker Compose

### Setup

1. Create `docker-compose.yml` in project root:

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "8002:8002"
    environment:
      - MONGO_URL=${MONGO_URL}
      - DB_NAME=drcode
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
      - CORS_ORIGINS=http://localhost:3001
    extra_hosts:
      - "host.docker.internal:host-gateway"

  frontend:
    build: ./frontend
    ports:
      - "3001:3001"
    environment:
      - REACT_APP_BACKEND_URL=http://localhost:8002
```

2. Create `.env` file:

```bash
MONGO_URL=mongodb+srv://<username>:<password>@cluster.mongodb.net/drcode
```

3. Build and run:

```bash
docker-compose up --build
```

### Notes

- `host.docker.internal` allows container to reach host's Ollama
- For production, use a reverse proxy (nginx/Traefik)

---

## 4. Pre-built Docker Images

Use pre-built images from GitHub Container Registry:

```bash
# Pull backend and frontend
docker pull ghcr.io/whoshotu/dr-code-v2-backend:latest
docker pull ghcr.io/whoshotu/dr-code-v2-frontend:latest

# Or use docker-compose:
docker-compose up -d
```

Images:
- `ghcr.io/whoshotu/dr-code-v2-backend:latest`
- `ghcr.io/whoshotu/dr-code-v2-frontend:latest`

---

## 5. Cloud Deployment

### Universal Container Approach

DR.CODE-v2 is a containerized app that can deploy to **any** container hosting service.

#### Build the Image

```bash
# From project root
docker build -t drcode-backend ./backend
docker build -t drcode-frontend ./frontend
```

Or use multi-stage build for combined image.

#### Required Environment Variables

| Variable | Description |
|----------|-------------|
| `MONGO_URL` | MongoDB Atlas connection string |
| `DB_NAME` | Database name |
| `OLLAMA_BASE_URL` | Ollama endpoint |
| `CORS_ORIGINS` | Frontend URL |
| `SECRET_KEY` | Encryption key (auto-generated if not set) |

#### Recommended Platforms

| Platform | Free Tier | Notes |
|----------|-----------|-------|
| **Doprax** | Yes | No CC required |
| **Koyeb** | Yes | No CC required |
| **Render** | Yes (sleeps) | CC required |
| **Fly.io** | $5 credit/mo | CC required |

#### Platform-Specific Notes

**Doprax:**
```bash
# Deploy via CLI or GitHub integration
doprax deploy --image drcode-backend
```

**Koyeb:**
```bash
# Connect GitHub repo, set env vars in dashboard
```

**Render:**
```bash
# Connect GitHub repo
# Set docker-compose.yml or Dockerfile path
```

---

## 6. Webhook Testing

### Why Webhooks?

Webhooks let GitHub notify DR.CODE when a PR is opened/updated, so the AI can automatically analyze code and post comments.

### Setup with ngrok

1. Start the backend:

```bash
cd backend
uvicorn server:app --port 8002
```

2. Create public tunnel (new terminal):

```bash
ngrok http 8002
```

3. Copy your ngrok URL (e.g., `https://abc123.ngrok.io`)

### Configure GitHub

1. Go to your repository → Settings → Webhooks → Add webhook
2. Fill in:

| Field | Value |
|-------|-------|
| Payload URL | `https://<ngrok-url>/api/integrations/git/webhook` |
| Content type | `application/json` |
| Secret | (optional) Enter a secret string |
| Events | Select "Pull requests" only |

3. Click "Add webhook"

### Configure DR.CODE

1. Open http://localhost:3001
2. Go to Settings
3. Enter your GitHub PAT in the GitHub Integration section
4. (Optional) Enter webhook secret to enable HMAC verification

### Testing

1. Create or update a PR
2. DR.CODE should:
   - Fetch the changed files
   - Run AI analysis
   - Post inline comments with fixes
   - Post a summary comment

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Webhook not firing | Check GitHub webhook delivery logs |
| 401 error | Verify webhook secret matches |
| No comments posted | Check GitHub PAT has `repo` + `pull_requests` scope |
| Analysis fails | Check Ollama is running and accessible |

---

## Features

- **Code Analysis** - Detect quality issues, security risks, and "slop"
- **Auto-Fix Suggestions** - AI-powered fix recommendations
- **Severity Levels** - Customizable critical/high/medium/low thresholds
- **Multi-Provider AI** - Ollama, OpenAI-compatible, Gemini, Anthropic
- **GitHub PR Integration** - Automated code review on PRs
- **Repository Scanning** - Multi-file analysis with bulk fixes

---

## Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `MONGO_URL` | Yes | MongoDB connection string |
| `DB_NAME` | Yes | Database name |
| `OLLAMA_BASE_URL` | Yes* | Ollama endpoint (*if AI enabled) |
| `OLLAMA_MODEL` | Yes* | Ollama model (*if AI enabled) |
| `CORS_ORIGINS` | Yes | Frontend URL(s), comma-separated |
| `SECRET_KEY` | No | Encryption key (auto-generated) |
| `GITHUB_TOKEN` | No | GitHub PAT for PR comments |
| `GITHUB_WEBHOOK_SECRET` | No | Webhook HMAC secret |

---

## Security Notes

- All API keys/tokens are encrypted with Fernet before storage
- Secrets are never returned in API responses
- Use environment variables for production secrets
- Never commit `.env` files to version control

---

## Need Help?

- Check the `memory/` folder for architecture docs
