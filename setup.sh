#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================"
echo "  DR.CODE v2 - Quick Setup"
echo -e "======================================${NC}"
echo ""

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        echo "Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker is not running${NC}"
        echo "Start Docker and try again"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker ready${NC}"
}

check_ollama() {
    if command -v ollama &> /dev/null; then
        if ollama list &> /dev/null; then
            echo -e "${GREEN}✓ Ollama installed${NC}"
            return 0
        fi
    fi
    return 1
}

start_ollama() {
    if ! check_ollama; then
        echo -e "${YELLOW}Installing Ollama...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh
        check_ollama
    fi
}

check_mongo() {
    # Check if MONGO_URL is already set in environment
    if [ -n "$MONGO_URL" ]; then
        return 0
    fi
    
    # Check in .env file
    if [ -f .env ] && grep -q "MONGO_URL=" .env; then
        source .env
        return 0
    fi
    
    # Check if MongoDB is already running (any container with "mongo" in name)
    if docker ps --format "{{.Names}}" | grep -qi "mongo"; then
        echo -e "${GREEN}✓ Found running MongoDB container${NC}"
        MONGO_URL="mongodb://mongo:27017"
        return 0
    fi
    
    # Check if port 27017 is in use on host (user's own MongoDB)
    if lsof -i :27017 &>/dev/null || netstat -tuln 2>/dev/null | grep -q ":27017"; then
        echo -e "${GREEN}✓ Found MongoDB on localhost:27017${NC}"
        MONGO_URL="mongodb://localhost:27017/drcode"
        return 0
    fi
    
    return 1
}

check_ollama() {
    # Check if Ollama is already running on localhost
    if curl -s http://localhost:11434/api/tags &>/dev/null; then
        echo -e "${GREEN}✓ Found Ollama on localhost:11434${NC}"
        OLLAMA_BASE_URL="http://localhost:11434"
        return 0
    fi
    
    # Check if Ollama is running in Docker
    if docker ps --format "{{.Names}}" | grep -qi "ollama"; then
        echo -e "${GREEN}✓ Found Ollama container${NC}"
        OLLAMA_BASE_URL="http://host.docker.internal:11434"
        return 0
    fi
    
    # Check environment variable
    if [ -n "$OLLAMA_BASE_URL" ]; then
        return 0
    fi
    
    return 1
}

setup_mongo() {
    echo ""
    echo -e "${CYAN}Step 1: MongoDB${NC}"
    
    # Auto-detect first
    if check_mongo; then
        echo -e "${GREEN}✓ MongoDB auto-detected: $MONGO_URL${NC}"
        return 0
    fi
    
    echo "  1) Use MongoDB Atlas (free cloud)"
    echo "  2) Use local MongoDB via Docker (default)"
    echo "  3) Skip (enter custom MONGO_URL)"
    echo ""
    read -p "Choose [2]: " mongo_choice
    mongo_choice=${mongo_choice:-2}
    
    if [ "$mongo_choice" = "1" ]; then
        echo ""
        echo "Get free MongoDB Atlas:"
        echo "  1. Go to https://www.mongodb.com/cloud/atlas"
        echo "  2. Create free account & cluster"
        echo "  3. Connect > Connect your application"
        echo "  4. Copy the connection string"
        echo ""
        read -p "Paste MONGO_URL: " MONGO_URL
    elif [ "$mongo_choice" = "2" ]; then
        if docker ps --format "{{.Names}}" | grep -qi "mongo"; then
            echo "MongoDB already running in Docker, using docker network"
            MONGO_URL="mongodb://mongo:27017/drcode"
        elif docker ps -a --format "{{.Names}}" | grep -qi "mongo"; then
            echo "Starting existing MongoDB container..."
            docker start $(docker ps -a --format "{{.Names}}" | grep -i "mongo" | head -1)
            MONGO_URL="mongodb://mongo:27017/drcode"
        else
            echo "Starting local MongoDB via Docker..."
            docker run -d -p 27017:27017 --name drcode-mongo mongo:7
            MONGO_URL="mongodb://mongo:27017/drcode"
        fi
    elif [ "$mongo_choice" = "3" ]; then
        read -p "Enter MONGO_URL: " MONGO_URL
    fi
    
    if [ -z "$MONGO_URL" ]; then
        echo -e "${RED}Error: MONGO_URL is required${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ MongoDB configured${NC}"
}

setup_ai() {
    echo ""
    echo -e "${CYAN}Step 2: AI Model${NC}"
    
    # Auto-detect first
    if check_ollama; then
        echo -e "${GREEN}✓ Ollama auto-detected: $OLLAMA_BASE_URL${NC}"
        return 0
    fi
    
    echo "  1) Ollama (local, free) - RECOMMENDED"
    echo "  2) LM Studio (local)"
    echo "  3) OpenAI (cloud)"
    echo "  4) Skip (configure later)"
    echo ""
    read -p "Choose [1]: " ai_choice
    ai_choice=${ai_choice:-1}
    
    if [ "$ai_choice" = "1" ]; then
        start_ollama
        OLLAMA_BASE_URL="http://host.docker.internal:11434"
        
        echo ""
        echo "Available models:"
        ollama list | grep -v "^$" | head -6
        
        read -p "Enter model [codellama]: " OLLAMA_MODEL
        OLLAMA_MODEL=${OLLAMA_MODEL:-codellama}
        
        if ! ollama list | grep -q "$OLLAMA_MODEL"; then
            echo "Pulling $OLLAMA_MODEL..."
            ollama pull "$OLLAMA_MODEL" || true
        fi
        
    elif [ "$ai_choice" = "2" ]; then
        OLLAMA_BASE_URL="http://host.docker.internal:1234/v1"
        read -p "Enter model [codellama]: " OLLAMA_MODEL
        OLLAMA_MODEL=${OLLAMA_MODEL:-codellama}
        
    elif [ "$ai_choice" = "3" ]; then
        read -p "Enter OpenAI API key: " OPENAI_API_KEY
        OLLAMA_BASE_URL="https://api.openai.com/v1"
        OLLAMA_MODEL="gpt-4"
        
    elif [ "$ai_choice" = "4" ]; then
        OLLAMA_BASE_URL="http://host.docker.internal:11434"
        OLLAMA_MODEL="codellama"
    fi
    
    echo -e "${GREEN}✓ AI configured: $OLLAMA_MODEL${NC}"
}

setup_github() {
    echo ""
    echo -e "${CYAN}Step 3: GitHub Integration (Optional)${NC}"
    echo "Press Enter to skip, or paste token to enable PR reviews"
    read -p "GitHub Token: " GITHUB_TOKEN
    if [ -n "$GITHUB_TOKEN" ]; then
        read -p "Webhook Secret (optional): " GITHUB_WEBHOOK_SECRET
    fi
}

save_config() {
    echo ""
    echo -e "${CYAN}Saving configuration...${NC}"
    
    # Save to .env for local development
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
    
    # Save to .env.docker for docker-compose (leave MongoDB/Ollama commented for auto-detect)
    cat > .env.docker << EOF
# DR.CODE-v2 Docker Environment
# Auto-generated by setup.sh

# MongoDB: Leave commented for auto-detect, or set explicitly
# MONGO_URL=$MONGO_URL

# Ollama: Leave commented for auto-detect, or set explicitly  
# OLLAMA_BASE_URL=$OLLAMA_BASE_URL
# OLLAMA_MODEL=$OLLAMA_MODEL

# Database
DB_NAME=drcode

# CORS
CORS_ORIGINS=http://localhost:3001
EOF

    if [ -n "$GITHUB_TOKEN" ]; then
        echo "GITHUB_TOKEN=$GITHUB_TOKEN" >> .env.docker
    fi
    if [ -n "$GITHUB_WEBHOOK_SECRET" ]; then
        echo "GITHUB_WEBHOOK_SECRET=$GITHUB_WEBHOOK_SECRET" >> .env.docker
    fi
    
    echo -e "${GREEN}✓ Config saved to .env and .env.docker${NC}"
}

start_services() {
    echo ""
    echo -e "${CYAN}Starting services...${NC}"
    
    # Create .env.docker from sample if it doesn't exist
    if [ ! -f .env.docker ]; then
        if [ -f .env.docker.sample ]; then
            cp .env.docker.sample .env.docker
        fi
    fi
    
    docker-compose up -d
    echo ""
    echo -e "${GREEN}======================================"
    echo "  DR.CODE v2 is Ready!"
    echo -e "======================================${NC}"
    echo ""
    echo "  Frontend: http://localhost:3001"
    echo "  Backend:  http://localhost:8002"
    echo ""
    echo "Commands:"
    echo "  make docker-up    # Start services"
    echo "  make docker-down # Stop services"
    echo "  make logs        # View logs"
    echo ""
}

quick_start() {
    echo -e "${YELLOW}Running in Quick Start mode...${NC}"
    
    check_docker
    
    # Check for existing MongoDB
    if ! check_mongo; then
        setup_mongo
    else
        echo -e "${GREEN}✓ Using existing MongoDB${NC}"
    fi
    
    # Check for existing Ollama
    if ! check_ollama; then
        setup_ai
    else
        echo -e "${GREEN}✓ Using existing Ollama: $OLLAMA_BASE_URL${NC}"
    fi
    
    save_config
    start_services
}

interactive_setup() {
    check_docker
    setup_mongo
    setup_ai
    setup_github
    save_config
    start_services
}

echo "Choose mode:"
echo "  1) Quick Start (recommended defaults)"
echo "  2) Interactive Setup (customize everything)"
echo ""
read -p "Choose [1]: " mode
mode=${mode:-1}

if [ "$mode" = "1" ]; then
    quick_start
else
    interactive_setup
fi
