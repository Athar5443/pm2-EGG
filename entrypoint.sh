#!/bin/bash

# Folder Tujuan
NODE_DIR="/home/container/node"
BUN_DIR="/usr/local/bun"
GO_DIR="/usr/local/go"
# Pastikan env Playwright terbawa
export PLAYWRIGHT_BROWSERS_PATH="/usr/local/share/playwright"

mkdir -p "$NODE_DIR"

echo "export PATH=\"$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:\$PATH\"" > /home/container/.bashrc
echo "export NODE_PATH=\"$NODE_DIR/lib/node_modules\"" >> /home/container/.bashrc
echo "export PLAYWRIGHT_BROWSERS_PATH=\"$PLAYWRIGHT_BROWSERS_PATH\"" >> /home/container/.bashrc
export PATH="$NODE_DIR/bin:$BUN_DIR/bin:$GO_DIR/bin:$PATH"

if [ ! -z "${NODE_VERSION}" ]; then
    if [ -x "$NODE_DIR/bin/node" ]; then
        CURRENT_VER=$("$NODE_DIR/bin/node" -v)
    else
        CURRENT_VER="none"
    fi

    echo "[AtharsCloud] Mengecek versi Node.js (Target: ${NODE_VERSION})..."
    TARGET_VER=$(curl -s https://nodejs.org/dist/index.json | jq -r '.[] | select(.version | startswith("v'${NODE_VERSION}'") or .version == "'${NODE_VERSION}'") | .version' | head -n 1)

    if [ -z "$TARGET_VER" ] || [ "$TARGET_VER" == "null" ]; then
        if [[ "${NODE_VERSION}" == v* ]]; then TARGET_VER="${NODE_VERSION}"; else TARGET_VER="v${NODE_VERSION}.0.0"; fi
        echo "[AtharsCloud] Gagal cek online. Menggunakan fallback: $TARGET_VER"
    fi

    if [[ "$CURRENT_VER" == "$TARGET_VER" ]]; then
        echo "[AtharsCloud] Node.js sudah versi terbaru ($CURRENT_VER)."
    else
        echo "[AtharsCloud] Mengunduh $TARGET_VER..."
        rm -rf $NODE_DIR/*
        cd /tmp
        
        curl -fL "https://nodejs.org/dist/${TARGET_VER}/node-${TARGET_VER}-linux-x64.tar.gz" -o node.tar.gz
        
        if [ $? -eq 0 ]; then
            echo "[AtharsCloud] Mengekstrak..."
            mkdir -p "$NODE_DIR"
            tar -xf node.tar.gz --strip-components=1 -C "$NODE_DIR"
            rm node.tar.gz
            
            echo "[AtharsCloud] Sukses! Terinstall: $("$NODE_DIR/bin/node" -v)"
            
            echo "[AtharsCloud] Installing Global Packages (PM2, Playwright, Puppeteer)..."
            "$NODE_DIR/bin/npm" install -g npm@latest pm2 pnpm yarn playwright puppeteer --loglevel=error
            echo "[AtharsCloud] Downloading Playwright Browsers to System Path..."
            "$NODE_DIR/bin/npx" playwright install --with-deps
        else
            echo "[AtharsCloud] ERROR DOWNLOAD. Cek koneksi."
        fi
        cd /home/container
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
echo "   AtharsCloud"
echo "========================================"
echo "Node       : $(node -v 2>/dev/null || echo 'ERROR')"
echo "Playwright : $(npx playwright --version 2>/dev/null || echo 'Not Installed')"
echo "Browser Dir: $PLAYWRIGHT_BROWSERS_PATH"
echo "----------------------------------------"

exec /bin/bash
