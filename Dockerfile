FROM node:18-alpine

# Set environment variables
ENV NVM_DIR=/root/.nvm \
    PATH=$NVM_DIR/versions/node/v18.12.0/bin:/root/.cargo/bin:/usr/local/go/bin:$PATH

# Install system dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    build-base \
    python3 \
    make \
    gcc \
    g++ \
    linux-headers \
    ca-certificates

# Install NVM and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install 18.12.0 && \
    nvm use 18.12.0 && \
    nvm alias default 18.12.0

# Install npm globally (ensure it's linked properly)
RUN . $NVM_DIR/nvm.sh && npm install -g npm@latest

# Install PM2 globally
RUN . $NVM_DIR/nvm.sh && npm install -g pm2

# Install Bun (for root user)
RUN curl -fsSL https://bun.sh/install | bash && \
    export PATH=$HOME/.bun/bin:$PATH && \
    chmod +x /root/.bun/bin/bun

# Install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz && \
    rm go1.21.0.linux-amd64.tar.gz && \
    /usr/local/go/bin/go version

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . $HOME/.cargo/env && \
    rustc --version

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node dependencies using npm from NVM
RUN . $NVM_DIR/nvm.sh && npm ci

# Copy application code
COPY . .

# Expose ports
EXPOSE 3000 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Default command
CMD [". $NVM_DIR/nvm.sh && pm2-runtime start ecosystem.config.js", "0"]

ENTRYPOINT ["/bin/bash", "-c"]
