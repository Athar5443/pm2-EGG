FROM debian:bullseye-slim

LABEL author="athar" \
      maintainer="athar@atharr.my.id"

ENV DEBIAN_FRONTEND=noninteractive \
    USER=container \
    HOME=/home/container \
    NODE_INSTALL_DIR=/home/container/node \
    BUN_INSTALL=/usr/local/bun

ENV PATH="$NODE_INSTALL_DIR/bin:$BUN_INSTALL/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl wget git zip unzip tar gzip bzip2 \
        jq nano vim sudo ca-certificates gnupg \
        net-tools iputils-ping dnsutils \
        build-essential make gcc g++ \
        python3 python3-pip \
        golang \
    && mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | gpg --dearmor > /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update && apt-get install -y cloudflared \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

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
