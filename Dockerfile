FROM debian:bullseye-slim

# Metadata
LABEL author="athar" \
      maintainer="athar@atharr.my.id" \
      description="AtharsCloud Ultimate: NVM, Node.js, Bun, Cloudflared, Python, Go, Rust & High Utilities."

# Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    # NVM Configuration
    NVM_DIR=/usr/local/nvm \
    NODE_VERSION=20.11.0 \
    # Bun Configuration
    BUN_INSTALL=/usr/local/bun \
    # User Configuration
    USER=container \
    HOME=/home/container

# 1. INSTALL SYSTEM DEPENDENCIES
# Menggabungkan apt-get untuk efisiensi. 
# Kita TIDAK menginstall 'nodejs' atau 'npm' dari apt untuk menghindari bentrok.
RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        curl wget git zip unzip tar gzip bzip2 p7zip-full zstd \
        jq nano vim bc time sudo lsb-release ca-certificates \
        net-tools iproute2 iputils-ping dnsutils \
        nmap iperf3 speedtest-cli aria2 \
        ffmpeg imagemagick graphicsmagick webp mediainfo \
        build-essential libtool make gcc g++ \
        mariadb-client postgresql-client redis-tools sqlite3 libsqlite3-dev \
        python3 python3-pip python3-dev python3-venv \
        tesseract-ocr \
        # Libraries untuk Puppeteer/Browser/Canvas
        fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 \
        libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 \
        libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 \
        libxrandr2 libxrender1 libxss1 libxtst6 \
        fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst \
        fonts-freefont-ttf fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --upgrade pip speedtest-cli

# 2. INSTALL CLOUDFLARE TUNNEL
RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

# 3. INSTALL NVM & NODE.JS
# Kita menggunakan shell bash untuk eksekusi script NVM
SHELL ["/bin/bash", "-c"]

RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    # Install Global Packages via NVM's NPM
    && npm install -g npm@latest pm2 yarn pnpm

# Set PATH agar Node/NPM/PM2 bisa dipanggil langsung tanpa 'source nvm.sh' terus menerus
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# 4. INSTALL BUN (Fixing missing Bun)
# Menginstall Bun ke direktori global (/usr/local/bun) agar bisa diakses user
RUN mkdir -p $BUN_INSTALL \
    && curl -fsSL https://bun.sh/install | bash \
    && mv /root/.bun/bin/bun $BUN_INSTALL/bun \
    && rm -rf /root/.bun

# Menambahkan Bun ke PATH
ENV PATH=$BUN_INSTALL:$PATH

# 5. USER SETUP
RUN useradd -m -d /home/container container

# Pastikan user container memiliki akses ke folder yang mungkin dibutuhkan
RUN chown -R container:container /home/container $NVM_DIR $BUN_INSTALL

USER container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
