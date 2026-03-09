# DR.CODE v2 Installer

One-command install for DR.CODE v2 - AI-powered code analysis platform.

## Quick Start

### Linux / Mac / WSL

```bash
curl -sL https://raw.githubusercontent.com/whoshotu/DR.Code-v2/main/drcode_installer/install.sh | bash
```

Or download and run:

```bash
chmod +x install.sh
./install.sh
```

### Windows

```powershell
irm https://raw.githubusercontent.com/whoshotu/DR.Code-v2/main/drcode_installer/install.ps1 | iex
```

Or download and run in PowerShell:

```powershell
.\install.ps1
```

---

## Requirements

- Docker 20.10+
- Docker Compose v2+
- Ports 3001, 8002, 27017 available

---

## Commands

| Command | Description |
|---------|-------------|
| `./install.sh` | Install and start (default) |
| `./install.sh start` | Start services |
| `./install.sh stop` | Stop services |
| `./install.sh status` | Show status |
| `./install.sh update` | Update to latest |
| `./install.sh clean` | Remove all data |

---

## After Install

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3001 |
| Backend | http://localhost:8002 |
| API | http://localhost:8002/api |

---

## Uninstall

```bash
./install.sh clean
```

This removes all containers and data.

---

## Configuration

Edit `.env.docker` to customize:

- `MONGO_URL` - MongoDB connection
- `OLLAMA_BASE_URL` - AI model endpoint
- `OLLAMA_MODEL` - AI model name

---

## Support

- Issues: https://github.com/whoshotu/DR.Code-v2/issues
