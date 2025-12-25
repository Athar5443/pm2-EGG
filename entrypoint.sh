#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
GO_DIR="/usr/local/go"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"

mkdir -p "$NODE_DIR"
echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc
echo "export PLAYWRIGHT_BROWSERS_PATH=\"$PLAYWRIGHT_BROWSERS_PATH\"" >> /home/container/.bashrc
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:$PATH"

if [ ! -z "${NODE_VERSION}" ]; then
    if [ -x "$NODE_DIR/bin/node" ]; then CURRENT_VER=$("$NODE_DIR/bin/node" -v); else CURRENT_VER="none"; fi
    
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r 'map(select(.version)) | .[] | select(.version | startswith("v'${NODE_VERSION}'")) | .version' 2>/dev/null | head -n 1)
    if [ -z "$TARGET_VER" ]; then TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | grep -o '"version":"v'${NODE_VERSION}'[^"]*"' | head -n 1 | cut -d'"' -f4); fi
    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
        if [[ "${NODE_VERSION}" == v* ]]; then TARGET_VER="${NODE_VERSION}"; else TARGET_VER="v${NODE_VERSION}.0.0"; fi
    fi

    if [[ "$CURRENT_VER" != "$TARGET_VER" ]]; then
        echo "[AtharsCloud] Installing Node.js $TARGET_VER..."
        rm -rf $NODE_DIR/* && cd /tmp
        curl -fL "https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz" -o node.tar.gz
        if [ $? -eq 0 ]; then
            mkdir -p "$NODE_DIR" && tar -xf node.tar.gz --strip-components=1 -C "$NODE_DIR" && rm node.tar.gz
            "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn playwright puppeteer --loglevel=error
            export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"
            "$NODE_DIR/bin/npx" --yes playwright install
        fi
        cd /home/container
    fi
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]] || [[ "${ENABLE_CF_TUNNEL}" == "1" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        pkill -f cloudflared 2>/dev/null
        rm -f /home/container/.cloudflared.log
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
    fi
fi

export USER=container
export HOME=/home/container
clear

# Warna
W="\033[1;37m" # Putih Tebal
C="\033[0;36m" # Cyan
G="\033[1;32m" # Hijau
Y="\033[1;33m" # Kuning
R="\033[1;31m" # Merah
N="\033[0m"    # Reset

# Ambil Data Sistem
LOC=$(curl -s ipinfo.io/country 2>/dev/null || echo "Unknown")
IP=$(curl -s ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')
OS=$(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '"')
KERNEL=$(uname -r)
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
UPTIME=$(uptime -p | sed 's/up //')

# RAM Usage
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_FREE=$(free -m | awk '/Mem:/ {print $4}')
RAM_PERC=$(( 100 * RAM_USED / RAM_TOTAL ))

DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_PERC=$(df -h / | awk 'NR==2 {print $5}')

NODE_V=$(node -v 2>/dev/null || echo "${R}Not Installed${N}")
BUN_V=$(bun -v 2>/dev/null || echo "${R}Not Installed${N}")
GO_V=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "${R}Not Installed${N}")
PY_V=$(python3 --version 2>/dev/null | awk '{print $2}' || echo "${R}Not Installed${N}")
PM2_V=$(pm2 -v 2>/dev/null || echo "${R}Not Installed${N}")

draw_bar() {
    perc=$1
    len=20
    fill=$(( (perc * len) / 100 ))
    empty=$(( len - fill ))
    
    if [ $perc -lt 50 ]; then bar_color=$G
    elif [ $perc -lt 80 ]; then bar_color=$Y
    else bar_color=$R; fi

    printf "${bar_color}["
    for ((i=0; i<fill; i++)); do printf "|"; done
    printf "${N}░"
    for ((i=0; i<empty-1; i++)); do printf "░"; done
    printf "${bar_color}] ${perc}%%${N}"
}

echo -e "${C}┌────────────────────────────────────────────────────────┐${N}"
echo -e "${C}│                  ${W}ATHARS CLOUD SYSTEM INFO${C}              │${N}"
echo -e "${C}├────────────────────────────────────────────────────────┤${N}"
echo -e "${C}│ ${W}Location   ${C}: ${W}$LOC${N}"
echo -e "${C}│ ${W}IP Address ${C}: ${W}$IP${N}"
echo -e "${C}│ ${W}OS         ${C}: ${W}$OS ($KERNEL)${N}"
echo -e "${C}│ ${W}CPU        ${C}: ${W}$CPU_MODEL${N}"
echo -e "${C}│ ${W}Cores      ${C}: ${W}$CPU_CORES Core(s)${N}"
echo -e "${C}│ ${W}Uptime     ${C}: ${W}$UPTIME${N}"
echo -e "${C}│${N}"
echo -e "${C}│ ${W}RAM Usage  ${C}: ${W}$RAM_USED MB / $RAM_TOTAL MB${N}"
echo -e "${C}│ ${W}Status     ${C}: $(draw_bar $RAM_PERC)"
echo -e "${C}│${N}"
echo -e "${C}│ ${W}Disk Usage ${C}: ${W}$DISK_USED / $DISK_TOTAL${N}"
echo -e "${C}│ ${W}Status     ${C}: $(draw_bar ${DISK_PERC%\%})"
echo -e "${C}├────────────────────────────────────────────────────────┤${N}"
echo -e "${C}│                  ${W}RUNTIME VERSIONS${C}                      │${N}"
echo -e "${C}├────────────────────────────────────────────────────────┤${N}"
echo -e "${C}│ ${W}Node.js    ${C}: ${G}$NODE_V${N}"
echo -e "${C}│ ${W}Bun        ${C}: ${G}v$BUN_V${N}"
echo -e "${C}│ ${W}Golang     ${C}: ${G}v$GO_V${N}"
echo -e "${C}│ ${W}Python     ${C}: ${G}v$PY_V${N}"
echo -e "${C}│ ${W}PM2        ${C}: ${G}v$PM2_V${N}"
echo -e "${C}└────────────────────────────────────────────────────────┘${N}"
echo ""

exec /bin/bash
