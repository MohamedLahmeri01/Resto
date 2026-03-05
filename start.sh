#!/bin/bash
# ============================================
#  Resto RMS - Auto Start Script
#  Usage: bash start.sh [edge|chrome|mobile|desktop]
# ============================================

set -e

TARGET="${1:-edge}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
BACKEND_PID=""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        kill "$BACKEND_PID" 2>/dev/null
        wait "$BACKEND_PID" 2>/dev/null
        echo -e "${GREEN}  Backend stopped.${NC}"
    fi
    echo -e "${GREEN}Done.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Resto RMS - Auto Start${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# ------------------------------------------
# 0. Kill any existing backend on port 3000
# ------------------------------------------
OLD_PID=$(lsof -ti:3000 2>/dev/null || netstat -ano 2>/dev/null | grep ':3000.*LISTENING' | awk '{print $NF}' || true)
if [ -n "$OLD_PID" ]; then
    echo -e "${YELLOW}  Killing old process on port 3000 (PID: $OLD_PID)...${NC}"
    kill -9 $OLD_PID 2>/dev/null || taskkill //F //PID $OLD_PID 2>/dev/null || true
    sleep 1
fi

# ------------------------------------------
# 1. Start Backend
# ------------------------------------------
echo -e "${YELLOW}[1/2] Starting backend server...${NC}"
cd "$BACKEND_DIR"
node src/app.js &
BACKEND_PID=$!
echo -e "${GREEN}  Backend PID: $BACKEND_PID${NC}"

# Wait for backend to be ready (max 30s)
echo -n "  Waiting for backend "
BACKEND_READY=false
for i in $(seq 1 30); do
    if curl.exe -s http://localhost:3000/health > /dev/null 2>&1 || curl -s http://localhost:3000/health > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}  Backend is ready on http://localhost:3000${NC}"
        BACKEND_READY=true
        break
    fi
    echo -n "."
    sleep 1
done

if [ "$BACKEND_READY" = false ]; then
    echo ""
    echo -e "${RED}  Backend failed to start! Check logs above.${NC}"
    exit 1
fi
echo ""

# ------------------------------------------
# 2. Start Flutter Frontend
# ------------------------------------------
echo -e "${YELLOW}[2/2] Starting Flutter frontend (target: $TARGET)...${NC}"
cd "$SCRIPT_DIR"

case "$TARGET" in
    edge)
        echo -e "${GREEN}  Launching on Microsoft Edge...${NC}"
        flutter run -d edge
        ;;
    chrome)
        echo -e "${GREEN}  Launching on Chrome...${NC}"
        flutter run -d chrome
        ;;
    mobile)
        echo -e "${GREEN}  Launching on connected mobile device...${NC}"
        flutter run
        ;;
    desktop)
        echo -e "${GREEN}  Launching as desktop app (Windows)...${NC}"
        flutter run -d windows
        ;;
    *)
        echo -e "${RED}  Unknown target: $TARGET${NC}"
        echo "  Usage: bash start.sh [edge|chrome|mobile|desktop]"
        exit 1
        ;;
esac
