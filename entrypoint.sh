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
        curl -sL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz -o node.tar.gz
        
        if [ $? -ne 0 ]; then
             echo "[AtharsCloud] Gagal download Node v${NODE_VERSION}. Cek koneksi/versi."
        else
            echo "[AtharsCloud] Mengekstrak..."
            tar -xf node.tar.gz
            mv node-v${NODE_VERSION}-linux-x64/* $NODE_DIR/
            rm -rf node.tar.gz node-v${NODE_VERSION}-linux-x64
            
            echo "[AtharsCloud] Node.js siap: $(node -v)"
            
            echo "[AtharsCloud] Menginstall Package Manager Global (npm, pm2, yarn)..."
            npm install -g npm@latest pm2 yarn pnpm
        fi
        cd /home/container
    else
        echo "[AtharsCloud] Node.js Version: $(node -v)"
    fi
else
    echo "[AtharsCloud] NODE_VERSION tidak diatur."
fi

if [[ "${ENABLE_CF_TUNNEL}" == "true" ]]; then
    if [ ! -z "${CF_TOKEN}" ]; then
        echo "[AtharsCloud] Menjalankan Cloudflare Tunnel..."
        
        pkill -f cloudflared

        # Hapus log lama
        rm -f /home/container/.cloudflared.log

        # Jalankan di background (nohup &) agar tidak mengganggu shell
        nohup cloudflared tunnel run --token ${CF_TOKEN} > /home/container/.cloudflared.log 2>&1 &
        
        sleep 2
        
        if pgrep -x "cloudflared" > /dev/null; then
            echo "[AtharsCloud] Tunnel BERJALAN di Background!"
            echo "[AtharsCloud] (Cek .cloudflared.log jika koneksi bermasalah)"
        else
            echo "[AtharsCloud] GAGAL menjalankan Tunnel. Cek Token Anda."
        fi
    else
        echo "[AtharsCloud] ERROR: Token CF_TOKEN kosong, tapi Tunnel diaktifkan."
    fi
else
    echo "[AtharsCloud] Cloudflare Tunnel: OFF"
fi

echo "========================================"
echo "   AtharsCloud Environment   "
echo "========================================"
echo "System Ready."
echo "Silakan ketik perintah Anda (node, pm2, git, ls, dll)."
echo "----------------------------------------"

cd /home/container || exit

exec ${STARTUP}
