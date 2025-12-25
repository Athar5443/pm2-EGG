FROM debian:bullseye-slim

# Metadata
LABEL author="athar" \
      maintainer="athar@atharr.my.id" \
      description="AtharsCloud Ultimate: Node.js, Playwright, Go 1.24, Python 3.13 & High Utilities."

ENV DEBIAN_FRONTEND=noninteractive \
    USER=container \
    HOME=/home/container \
    NODE_INSTALL_DIR=/home/container/node \
    BUN_INSTALL=/usr/local/bun \
    PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright \
    # Versi Software
    GO_VERSION=1.24.0 \
    PYTHON_VERSION=3.13.0

# PATH Setup
ENV PATH="$NODE_INSTALL_DIR/bin:$BUN_INSTALL/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git zip unzip tar gzip bzip2 p7zip-full zstd \
        jq nano vim sudo ca-certificates gnupg lsb-release \
        net-tools iputils-ping dnsutils \
        build-essential make gcc g++ libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev llvm \
        libncurses5-dev libncursesw5-dev xz-utils tk-dev \
        libffi-dev liblzma-dev python3-openssl \
        ffmpeg imagemagick graphicsmagick webp mediainfo \
    && mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor > /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared

RUN apt-get install -y --no-install-recommends \
        fonts-liberation fonts-noto-color-emoji fonts-freefont-ttf \
        libfontconfig1 libfreetype6 \
        libasound2 libgstreamer-gl1.0-0 libgstreamer-plugins-bad1.0-0 \
        libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 \
        libgbm1 libgtk-3-0 libx11-xcb1 libxcb-dri3-0 libxss1 libxtst6 \
        libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
        libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxshmfence1 \
        libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libdbus-1-3 libexpat1 libgcc1 libglib2.0-0 \
        libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libjpeg62-turbo-dev \
        libgif-dev librsvg2-dev \
        libenchant-2-2 libsecret-1-0 libmanette-0.2-0 xdg-utils \
    && rm -rf /var/lib/apt/lists/*
RUN cd /tmp \
    && wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz || wget https://go.dev/dl/go1.23.4.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go*.linux-amd64.tar.gz \
    && rm go*.linux-amd64.tar.gz

RUN cd /tmp \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python3 \
    && ln -sf /usr/local/bin/python3.13 /usr/local/bin/python \
    && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip3 \
    && ln -sf /usr/local/bin/pip3.13 /usr/local/bin/pip \
    && cd .. && rm -rf Python-${PYTHON_VERSION}* \
    && pip3 install --upgrade pip

RUN mkdir -p $BUN_INSTALL \
    && curl -fsSL https://bun.sh/install | bash \
    && chown -R root:root $BUN_INSTALL \
    && chmod -R 755 $BUN_INSTALL

RUN mkdir -p $PLAYWRIGHT_BROWSERS_PATH && chmod -R 777 $PLAYWRIGHT_BROWSERS_PATH

RUN useradd -m -d /home/container container
RUN mkdir -p $NODE_INSTALL_DIR && chown -R container:container $NODE_INSTALL_DIR

USER container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD [ "/bin/bash", "/entrypoint.sh" ]
