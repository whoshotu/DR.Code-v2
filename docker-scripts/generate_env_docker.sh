#!/bin/bash
set -euo pipefail

# Create a minimal env file for Docker Compose from secrets (to avoid committing secrets)
KEEP_VARS=(MONGO_URL OLLAMA_BASE_URL OLLAMA_MODEL DB_NAME GITHUB_TOKEN GITHUB_WEBHOOK_SECRET)
ENV_FILE=.env.docker

echo "# Auto-generated from GitHub Secrets (run in CI)" > "$ENV_FILE"

for VAR in ${KEEP_VARS[@]}; do
  if [ -n "${!VAR:-}" ]; then
    echo "$VAR=${!VAR}" >> "$ENV_FILE"
  fi
done

echo "Wrote $ENV_FILE with: ${KEEP_VARS[*]}"
