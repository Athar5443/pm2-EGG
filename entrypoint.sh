#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"

echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc

export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$PATH"

if [ ! -z "${NODE_VERSION}" ]; then
    if [ -x "$NODE_DIR/bin/node" ]; then
        CURRENT_VER=$("$NODE_DIR/bin/node" -v | cut -d 'v' -f 2)
    else
        CURRENT_VER="none"
    fi

    if [[ "$CURRENT_VER" != "$NODE_VERSION"* ]]; then
        echo "[AtharsCloud] Installing Node.js v${NODE_VERSION}..."
        
        rm -rf $NODE_DIR/*
        
        cd /tmp
        curl -sL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz -o node.tar.gz
        
        if [ $? -eq 0 ]; then
            tar -xf node.tar.gz --strip-components=1 -C $NODE_DIR
            rm node.tar.gz
            echo "[AtharsCloud] Node.js updated."
            
            echo "[AtharsCloud] Installing PM2 & Package Managers..."
            "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn
        else
            echo "[AtharsCloud] GAGAL download Node.js. Cek koneksi internet server."
        fi
        cd /home/container
    fi
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]] && [[ ! -z "${CF_TOKEN}" ]]; then
    echo "[AtharsCloud] Starting Tunnel..."
    pkill -f cloudflared 2>/dev/null
    rm -f /home/container/.cloudflared.log
    
    nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
fi

export USER=container
export HOME=/home/container

echo "========================================"
echo "   AtharsCloud System Ready             "
echo "========================================"
echo "Node : $(node -v 2>/dev/null || echo 'ERROR')"
echo "PM2  : $(pm2 -v 2>/dev/null || echo 'ERROR')"
echo "Bun  : $(bun -v 2>/dev/null || echo 'ERROR')"
echo "Go   : $(go version 2>/dev/null || echo 'ERROR')"
echo "----------------------------------------"

# Buka Bash Shell (Terminal Interaktif)
exec /bin/bash
