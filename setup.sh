#!/bin/bash

set -e

echo "======================================"
echo "  DR.CODE v2 - Easy Setup"
echo "======================================"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}Docker found!${NC}"
echo ""

echo "======================================"
echo "  Step 1: MongoDB Setup"
echo "======================================"
echo ""
echo "You need a MongoDB database. Options:"
echo "  1. MongoDB Atlas (free cloud) - RECOMMENDED"
echo "  2. Local MongoDB via Docker"
echo ""
read -p "Choose (1/2): " mongo_choice

if [ "$mongo_choice" = "1" ]; then
    echo ""
    echo "Get free MongoDB Atlas:"
    echo "  1. Go to https://www.mongodb.com/cloud/atlas"
    echo "  2. Create free account"
    echo "  3. Create free cluster"
    echo "  4. Connect > Connect your application > Python"
    echo "  5. Copy the connection string"
    echo ""
    read -p "Paste your MongoDB connection string: " MONGO_URL
    
    if [ -z "$MONGO_URL" ]; then
        echo -e "${RED}Error: No connection string provided${NC}"
        exit 1
    fi
elif [ "$mongo_choice" = "2" ]; then
    echo "Starting local MongoDB..."
    docker run -d -p 27017:27017 --name mongodb mongo:latest
    MONGO_URL="mongodb://localhost:27017/drcode"
else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
fi

echo ""

echo "======================================"
echo "  Step 2: AI Model Setup"
echo "======================================"
echo ""
echo "Choose your AI model provider:"
echo "  1. Ollama (local, free) - RECOMMENDED"
echo "  2. LM Studio (local)"
echo "  3. OpenAI (cloud, requires API key)"
echo "  4. Skip for now"
echo ""
read -p "Choose (1/2/3/4): " model_choice

if [ "$model_choice" = "1" ]; then
    echo ""
    if command -v ollama &> /dev/null; then
        echo "Ollama already installed"
    else
        echo "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    echo ""
    read -p "Enter Ollama model (default: codellama): " OLLAMA_MODEL
    OLLAMA_MODEL=${OLLAMA_MODEL:-codellama}
    OLLAMA_BASE_URL="http://host.docker.internal:11434"
    
    echo "Pulling $OLLAMA_MODEL model..."
    ollama pull $OLLAMA_MODEL 2>/dev/null || echo "Model pull failed, will use available models"
    
elif [ "$model_choice" = "2" ]; then
    echo "LM Studio detected at http://localhost:1234/v1"
    OLLAMA_BASE_URL="http://host.docker.internal:1234/v1"
    read -p "Enter model name (default: codellama): " OLLAMA_MODEL
    OLLAMA_MODEL=${OLLAMA_MODEL:-codellama}
    
elif [ "$model_choice" = "3" ]; then
    echo ""
    read -p "Enter OpenAI API key: " OPENAI_API_KEY
    OLLAMA_BASE_URL="https://api.openai.com/v1"
    OLLAMA_MODEL="gpt-4"
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" > .env.local
    
elif [ "$model_choice" = "4" ]; then
    OLLAMA_BASE_URL="http://host.docker.internal:11434"
    OLLAMA_MODEL="codellama"
else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
fi

echo ""

echo "======================================"
echo "  Step 3: GitHub Integration (Optional)"
echo "======================================"
echo ""
read -p "Add GitHub token for PR reviews? (y/n): " github_choice

GITHUB_TOKEN=""
GITHUB_WEBHOOK_SECRET=""

if [ "$github_choice" = "y" ]; then
    echo ""
    echo "Get token at: https://github.com/settings/tokens"
    echo "  - Select 'repo' scope"
    echo "  - Select 'pull_requests:write' scope"
    read -p "Paste GitHub token: " GITHUB_TOKEN
    read -p "Enter webhook secret (optional): " GITHUB_WEBHOOK_SECRET
fi

echo ""

echo "======================================"
echo "  Creating Configuration..."
echo "======================================"
echo ""

cat > .env << EOF
MONGO_URL=$MONGO_URL
OLLAMA_BASE_URL=$OLLAMA_BASE_URL
OLLAMA_MODEL=$OLLAMA_MODEL
CORS_ORIGINS=http://localhost:3001
DB_NAME=drcode
EOF

if [ -n "$GITHUB_TOKEN" ]; then
    echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> .env
fi

if [ -n "$GITHUB_WEBHOOK_SECRET" ]; then
    echo "GITHUB_WEBHOOK_SECRET=$GITHUB_WEBHOOK_SECRET" >> .env
fi

echo -e "${GREEN}Configuration saved to .env${NC}"

echo ""
echo "======================================"
echo "  Starting DR.CODE v2"
echo "======================================"
echo ""

echo -e "${GREEN}Starting containers...${NC}"
docker-compose up -d

echo ""
echo "======================================"
echo "  Done!"
echo "======================================"
echo ""
echo "Access at:"
echo "  - Frontend: http://localhost:3001"
echo "  - Backend:  http://localhost:8002"
echo "  - API:      http://localhost:8002/api"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop:      docker-compose down"
echo ""
