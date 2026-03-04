#!/usr/bin/env bash
set -euo pipefail

# Ubuntu-friendly Ollama restart helper
# Usage: ./tools/ollama_restart_ubuntu.sh [PORT]

PORT=${1:-11434}

echo "Restarting Ollama on port ${PORT}..."

# Try to free the port if something is listening
if command -v fuser >/dev/null 2>&1; then
  sudo fuser -k "${PORT}/tcp" 2>/dev/null || true
fi

if command -v ollama >/dev/null 2>&1; then
  echo "Starting Ollama..."
  if command -v nohup >/dev/null 2>&1; then
    nohup ollama serve --port "${PORT}" > "/tmp/ollama_${PORT}.log" 2>&1 &
  else
    ollama serve --port "${PORT}" &
  fi
else
  echo "Error: Ollama binary not found in PATH." >&2
  exit 1
fi

echo "Waiting for Ollama to become ready..."
for i in {1..60}; do
  if curl -s --max-time 2 "http://127.0.0.1:${PORT}/api/tags" >/dev/null; then
    echo "Ollama is ready on port ${PORT}."
    exit 0
  fi
  sleep 0.5
done

exit 1
