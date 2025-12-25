FROM debian:bullseye-slim

# Metadata
LABEL author="athar" \
      maintainer="athar@atharr.my.id" \
      description="AtharsCloud Ultimate: Node.js (Manual Switch), Bun, Python, Go, Rust & High Utilities."

ENV DEBIAN_FRONTEND=noninteractive \
    USER=container \
    HOME=/home/container \
    NODE_INSTALL_DIR=/home/container/node \
    BUN_INSTALL=/usr/local/bun

# Set Path: Node.js, Bun, dan System Path
ENV PATH="$NODE_INSTALL_DIR/bin:$BUN_INSTALL/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
        curl wget git zip unzip tar gzip bzip2 p7zip-full zstd \
        jq nano vim bc time sudo lsb-release ca-certificates gnupg \
        net-tools iproute2 iputils-ping dnsutils \
        nmap iperf3 speedtest-cli aria2 \
        ffmpeg imagemagick graphicsmagick webp mediainfo \
        build-essential libtool make gcc g++ \
        mariadb-client postgresql-client redis-tools sqlite3 libsqlite3-dev \
        python3 python3-pip python3-dev python3-venv \
        tesseract-ocr \
        fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 \
        libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 \
        libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 \
        libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 \
        libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 \
        libxrandr2 libxrender1 libxss1 libxtst6 \
        fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst \
        fonts-freefont-ttf fonts-noto-color-emoji \
    \
    && mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor > /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared \
    \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --upgrade pip speedtest-cli

RUN mkdir -p $BUN_INSTALL \
    && curl -fsSL https://bun.sh/install | bash \
    && chown -R root:root $BUN_INSTALL \
    && chmod -R 755 $BUN_INSTALL

RUN useradd -m -d /home/container container

RUN mkdir -p $NODE_INSTALL_DIR && chown -R container:container $NODE_INSTALL_DIR

USER container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
