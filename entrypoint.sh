#!/bin/bash

# Load NVM Environment
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Warna Output
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
NC='\033[0m'

if [ ! -z "${NODE_VERSION}" ]; then
    CURRENT_NODE=$(node -v)
    if [[ "$CURRENT_NODE" != *"$NODE_VERSION"* ]]; then
        echo -e "${CYAN}[AtharsCloud] Switch Node.js ke versi: ${NODE_VERSION}...${NC}"
        
        # Install dan gunakan versi baru
        nvm install ${NODE_VERSION}
        nvm use ${NODE_VERSION}
        nvm alias default ${NODE_VERSION}
        
        # Re-install global packages untuk versi baru ini agar command pm2/yarn jalan
        echo -e "${GREEN}[AtharsCloud] Re-installing PM2 & NPM for Node ${NODE_VERSION}...${NC}"
        npm install -g npm@latest pm2 yarn pnpm
    else
        echo -e "${GREEN}[AtharsCloud] Node.js version verified: ${CURRENT_NODE}${NC}"
    fi
else
    echo -e "${YELLOW}[AtharsCloud] Menggunakan Node.js default image.${NC}"
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        echo -e "${CYAN}[AtharsCloud] Starting Cloudflare Tunnel...${NC}"
        
        # Jalankan di background, output log disembunyikan agar tidak spam console
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
        
        echo -e "${GREEN}[AtharsCloud] Cloudflare Tunnel AKTIF! 🚀${NC}"
        echo -e "${YELLOW}(Tunnel berjalan di background. Cek Dashboard Cloudflare untuk status online)${NC}"
    else
        echo -e "${RED}[AtharsCloud] ERROR: Token Cloudflare kosong! Tunnel GAGAL dijalankan.${NC}"
    fi
else
    echo -e "${YELLOW}[AtharsCloud] Cloudflare Tunnel dinonaktifkan (User disabled).${NC}"
fi

clear
echo -e "${RED}"
echo "=============================="
echo -e "     ${MAGENTA}Welcome to AtharsCloud${NC}     "
echo "=============================="
echo -e "${NC}"
sleep 1

# Informasi Sistem
OS=$(lsb_release -d | awk -F'\t' '{print $2}')
IP=$(hostname -I | awk '{print $1}')
CPU=$(grep -m1 'model name' /proc/cpuinfo | awk -F': ' '{print $2}')
RAM=$(awk '/MemTotal/ {printf "%.2f GB", $2/1024/1024}' /proc/meminfo)
DISK=$(df -h / | awk '/\/$/ {print $2}')
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${GREEN}System Details:${NC}"
echo -e "${MAGENTA}CPU       : ${CYAN}$CPU${NC}"
echo -e "${GREEN}RAM       : ${CYAN}$RAM${NC}"
echo -e "${CYAN}Date      : ${NC}$DATE"
echo -e "------------------------------"

cd /home/container || exit

echo -e "${GREEN}Running Runtime:${NC} $(node -v) / NPM $(npm -v)"

MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')

echo -e "${CYAN}Startup Command:${NC} ${MODIFIED_STARTUP}"

# Jalankan Server
echo -e "${YELLOW}Starting the application...${NC}"
eval ${MODIFIED_STARTUP}
