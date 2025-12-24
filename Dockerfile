FROM debian:bullseye-slim

# Metadata
LABEL author="athar" \
      maintainer="athar@atharr.my.id" \
      description="AtharsCloud Ultimate: NVM, Cloudflared, Python, Go, Rust & High Utilities."

# Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    NVM_DIR=/usr/local/nvm \
    NODE_VERSION=22.12.0

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        curl wget git zip unzip tar gzip bzip2 p7zip-full zstd \
        jq nano vim bc time sudo lsb-release ca-certificates \
        net-tools iproute2 iputils-ping dnsutils \
        nmap iperf3 speedtest-cli aria2 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        ffmpeg imagemagick graphicsmagick webp mediainfo \
        build-essential libtool make gcc g++ \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        mariadb-client postgresql-client redis-tools sqlite3 libsqlite3-dev \
        python3 python3-pip python3-dev python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --upgrade pip speedtest-cli

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        tesseract-ocr \
        fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 \
        libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 \
        libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 \
        libxrandr2 libxrender1 libxss1 libxtst6 \
        fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst \
        fonts-freefont-ttf fonts-noto-color-emoji \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# 5. INSTALL CLOUDFLARE TUNNEL
# ==============================================================================
RUN curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
    && dpkg -i cloudflared.deb \
    && rm cloudflared.deb

SHELL ["/bin/bash", "-c"]

RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm install -g npm@latest pm2 yarn pnpm

# Tambahkan NVM ke PATH
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN useradd -m -d /home/container container

USER container
ENV USER=container \
    HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
