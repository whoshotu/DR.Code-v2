DR.CODE v2 - Local Docker Dev Quickstart

Goals:
- Run the full stack locally in Docker without exposing secrets in code
- Use a local MongoDB container and a local model provider
- Persist sanitizer UI state in the browser and ensure no-slop in generated code

Prereqs:
- Docker and Docker Compose installed
- Optional: a local model server (default Ollama port 11434)

1) Prepare environment file (no secrets in code)
- Create a local copy of the env file from the sample, e.g.:
  cp .env.docker.sample .env.docker
- Edit .env.docker to fill in MONGO_URL, OLLAMA_BASE_URL, OLLAMA_MODEL as needed. Do not commit this file.

2) Build and start services
- docker-compose up --build
- This will bring up: backend (uvicorn), frontend (nginx), and mongo (local) if you enable it

3) Access and verify
- Frontend: http://localhost:3001
- Backend health: http://localhost:8002/health or /api/health

4) Enable sanitizer in UI
- Open the dashboard and toggle Sanitizer to ON. This persists in your browser.

5) End-to-end tests
- Use three endpoints: /api/generate/tests, /api/generate/docstrings, /api/generate/diagram
- Check syntax for Python/JS, ensure Mermaid diagram renders

Notes:
- This guide avoids embedding secrets in code; secrets live in .env.docker created locally or via CI.
- If you want to revert to Atlas or to a remote MongoDB, switch MONGO_URL accordingly in the .env.docker.
