#!/bin/bash

NODE_DIR="/home/container/node"
export PATH="$NODE_DIR/bin:$PATH"

if [ ! -z "${NODE_VERSION}" ]; then
    if [ -f "$NODE_DIR/bin/node" ]; then
        CURRENT_NODE_VER=$(node -v | cut -d 'v' -f 2)
    else
        CURRENT_NODE_VER="none"
    fi

    if [[ "$CURRENT_NODE_VER" != "$NODE_VERSION"* ]]; then
        echo "[AtharsCloud] Mendeteksi perubahan versi Node.js..."
        echo "[AtharsCloud] Mengunduh Node.js v${NODE_VERSION}..."

        rm -rf $NODE_DIR/*

        cd /tmp
        # Download binary resmi
        curl -sL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz -o node.tar.gz
        
        if [ $? -ne 0 ]; then
             echo "[AtharsCloud] Gagal download Node v${NODE_VERSION}. Cek versi!"
        else
            echo "[AtharsCloud] Mengekstrak..."
            tar -xf node.tar.gz
            mv node-v${NODE_VERSION}-linux-x64/* $NODE_DIR/
            rm -rf node.tar.gz node-v${NODE_VERSION}-linux-x64
            
            echo "[AtharsCloud] Node.js updated to $(node -v)!"
            
            echo "[AtharsCloud] Installing PM2, Yarn, PNPM..."
            npm install -g npm@latest pm2 yarn pnpm
        fi
        cd /home/container
    else
        echo "[AtharsCloud] Node.js version: $(node -v)"
    fi
else
    echo "[AtharsCloud] NODE_VERSION variable not set."
fi

# --- 2. LOGIKA CLOUDFLARE TUNNEL ---
if [[ "${ENABLE_CF_TUNNEL}" == "true" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        echo "[AtharsCloud] Starting Cloudflare Tunnel..."
        
        # Hapus log lama jika ada
        rm -f /home/container/.cloudflared.log

        # Jalankan tunnel di background
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
        
        sleep 3
        
        if pgrep -x "cloudflared" > /dev/null; then
            echo "[AtharsCloud] Cloudflare Tunnel BERJALAN!"
            echo "(Cek file .cloudflared.log untuk detail koneksi)"
        else
            echo "[AtharsCloud] GAGAL menjalankan Tunnel. Cek Token atau Log."
            cat /home/container/.cloudflared.log
        fi
    else
        echo "[AtharsCloud] ERROR: Token Cloudflare (CF_TOKEN) kosong!"
    fi
else
    echo "[AtharsCloud] Cloudflare Tunnel dinonaktifkan."
fi

clear
echo "========================================"
echo "   AtharsCloud Ultimate Node.js Panel   "
echo "========================================"

# Tampilkan versi Runtime
echo "Node.js : $(node -v 2>/dev/null || echo 'Not Installed')"
echo "Bun     : $(bun -v 2>/dev/null || echo 'Not Installed')"
echo "Python  : $(python3 --version 2>/dev/null || echo 'Not Installed')"
echo "----------------------------------------"

cd /home/container || exit

# Replace variable startup Pterodactyl
MODIFIED_STARTUP=$(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo "Startup Command: ${MODIFIED_STARTUP}"

# Jalankan Server
eval ${MODIFIED_STARTUP}
