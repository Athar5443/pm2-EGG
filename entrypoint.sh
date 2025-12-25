#!/bin/bash

NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
GO_DIR="/usr/local/go"

echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:$PATH"

if [ ! -z "${NODE_VERSION}" ]; then
    # Cek versi terinstall saat ini
    if [ -x "$NODE_DIR/bin/node" ]; then
        CURRENT_VER=$("$NODE_DIR/bin/node" -v)
    else
        CURRENT_VER="none"
    fi

    echo "[AtharsCloud] Mengecek versi terbaru untuk Node v${NODE_VERSION}..."
    
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r '.[] | select(.version | startswith("v'${NODE_VERSION}'")) | .version' | head -n 1)

    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
        echo "[AtharsCloud] GAGAL menemukan versi Node v${NODE_VERSION}. Memakai fallback v${NODE_VERSION}.0.0 (Mungkin gagal)..."
        TARGET_VER="v${NODE_VERSION}.0.0"
    fi

    # Bandingkan apakah perlu update
    if [[ "$CURRENT_VER" != "$TARGET_VER" ]]; then
        echo "[AtharsCloud] Mengunduh ${TARGET_VER}..."
        
        rm -rf $NODE_DIR/*
        cd /tmp
        
        DOWNLOAD_URL="https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz"
        
        curl -fL "$DOWNLOAD_URL" -o node.tar.gz
        
        if [ $? -eq 0 ]; then
            echo "[AtharsCloud] Mengekstrak..."
            tar -xf node.tar.gz --strip-components=1 -C $NODE_DIR
            rm node.tar.gz
            
            echo "[AtharsCloud] Sukses! Terinstall: $("$NODE_DIR/bin/node" -v)"
            
            echo "[AtharsCloud] Installing PM2, Yarn, PNPM..."
            "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn --loglevel=error
        else
            echo "[AtharsCloud] ERROR DOWNLOAD: Link tidak ditemukan ($DOWNLOAD_URL)"
            echo "Pastikan versi Node.js yang Anda masukkan benar (misal: 18, 20, 21)."
        fi
        cd /home/container
    else
        echo "[AtharsCloud] Node.js sudah update: $CURRENT_VER"
    fi
else
    echo "[AtharsCloud] Peringatan: NODE_VERSION tidak diatur."
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
echo "   AtharsCloud System Ready (v2.0)      "
echo "========================================"
echo "Node : $(node -v 2>/dev/null || echo 'ERROR')"
echo "PM2  : $(pm2 -v 2>/dev/null || echo 'ERROR')"
echo "Bun  : $(bun -v 2>/dev/null || echo 'ERROR')"
echo "Go   : $(go version 2>/dev/null || echo 'ERROR')"
echo "----------------------------------------"

exec /bin/bash
