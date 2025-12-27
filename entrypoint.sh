#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
GO_DIR="/usr/local/go"
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"

mkdir -p "$NODE_DIR"
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:$PATH"

echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc
echo "export PLAYWRIGHT_BROWSERS_PATH=\"$PLAYWRIGHT_BROWSERS_PATH\"" >> /home/container/.bashrc

if [ ! -z "${NODE_VERSION}" ]; then
    [ -x "$NODE_DIR/bin/node" ] && CURRENT_VER=$("$NODE_DIR/bin/node" -v) || CURRENT_VER="none"
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r 'map(select(.version)) | .[] | select(.version | startswith("v'${NODE_VERSION}'")) | .version' 2>/dev/null | head -n 1)
    
    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
         if [[ "${NODE_VERSION}" == v* ]]; then TARGET_VER="${NODE_VERSION}"; else TARGET_VER="v${NODE_VERSION}.0.0"; fi
    fi

    if [[ "$CURRENT_VER" != "$TARGET_VER" ]]; then
        rm -rf $NODE_DIR/* && cd /tmp
        curl -fL "https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz" -o node.tar.gz
        tar -xf node.tar.gz --strip-components=1 -C "$NODE_DIR" && rm node.tar.gz
        "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn playwright --loglevel=error
        cd /home/container
    fi
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]] || [[ "${ENABLE_CF_TUNNEL}" == "1" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        pkill -f cloudflared 2>/dev/null
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
    fi
fi

clear
echo "----------------------------------------------------------"
echo "                    ATHARS CLOUD SYSTEM                   "
echo "----------------------------------------------------------"
echo "Location   : $(curl -s ipinfo.io/country 2>/dev/null || echo 'Unknown')"
echo "OS         : $(grep -oP '(?<=^PRETTY_NAME=).+' /etc/os-release | tr -d '\"')"
echo "CPU        : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //') ($(( $(grep -c ^processor /proc/cpuinfo) )) Cores)"
echo "Uptime     : $(uptime -p | sed 's/up //')"
echo ""
echo "RAM Usage  : $(free -m | awk '/Mem:/ {print $3" MB / "$2" MB"}')"
echo "Disk Usage : $(df -h / | awk 'NR==2 {print $3" / "$2" ("$5")"}')"
echo "----------------------------------------------------------"
echo "                     RUNTIME VERSIONS                     "
echo "----------------------------------------------------------"
echo "Node.js    : $(node -v 2>/dev/null || echo 'Not Installed')"
echo "Bun        : v$(bun -v 2>/dev/null || echo 'Not Installed')"
echo "Golang     : v$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo 'Not Installed')"
echo "Python     : v$(python3 --version 2>/dev/null | awk '{print $2}' || echo 'Not Installed')"
echo "Playwright : $(playwright --version 2>/dev/null | head -n 1 || echo 'Not Installed')"
echo "----------------------------------------------------------"

exec /bin/bash
