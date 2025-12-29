FROM debian:bullseye-slim

LABEL author="athar" maintainer="athar@atharr.my.id"

ENV DEBIAN_FRONTEND=noninteractive \
    USER=container \
    HOME=/home/container \
    NODE_INSTALL_DIR=/home/container/node \
    BUN_INSTALL=/usr/local/bun \
    PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright \
    GO_VERSION=1.24.0 \
    PYTHON_VERSION=3.13.0

ENV PATH="$NODE_INSTALL_DIR/bin:$BUN_INSTALL/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git zip unzip tar gzip bzip2 p7zip-full zstd \
        jq nano vim sudo ca-certificates gnupg lsb-release \
        net-tools iputils-ping dnsutils procps \
        build-essential make gcc g++ libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev \
        libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev \
        ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavdevice-dev imagemagick graphicsmagick webp mediainfo \
    && mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor > /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared

RUN apt-get install -y --no-install-recommends \
        fonts-liberation fonts-noto-color-emoji libfontconfig1 libfreetype6 \
        libasound2 libgbm1 libgtk-3-0 libnss3 libnspr4 libatk1.0-0 \
        libatk-bridge2.0-0 libcups2 libdrm2 libdbus-1-3 libexpat1 \
        libx11-xcb1 libxcb-dri3-0 libxss1 libxtst6 \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && rm go*.tar.gz

RUN cd /tmp && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations && make altinstall \
    && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip3 \
    && cd .. && rm -rf Python-${PYTHON_VERSION}*

RUN cd /tmp && wget https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip \
    && unzip bun-linux-x64.zip \
    && mkdir -p $BUN_INSTALL/bin \
    && mv bun-linux-x64/bun $BUN_INSTALL/bin/bun \
    && chmod +x $BUN_INSTALL/bin/bun \
    && rm -rf bun-linux-x64 bun-linux-x64.zip

RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g playwright \
    && npx playwright install --with-deps \
    && apt-get purge -y nodejs && apt-get autoremove -y \
    && chmod -R 777 $PLAYWRIGHT_BROWSERS_PATH

RUN useradd -m -d /home/container container
RUN mkdir -p $NODE_INSTALL_DIR && chown -R container:container $NODE_INSTALL_DIR

USER container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
