# ==============================================================================
# Stage 1: claude-code-base
# Claude Code基盤（node:20ベース）
# ==============================================================================
FROM node:20 AS claude-code-base

ARG TZ
ENV TZ="$TZ"

# Claude Code基本パッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    man-db \
    unzip \
    gnupg2 \
    gh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    nano \
    vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

ARG USERNAME=node

# Persist bash history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory

# Set `DEVCONTAINER` environment variable to help with orientation
ENV DEVCONTAINER=true

# Create workspace and config directories and set permissions
RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# Install git-delta
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# ==============================================================================
# Stage 2: with-flutter
# Flutter環境追加
# ==============================================================================
FROM claude-code-base AS with-flutter

# Flutterパッケージのインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    xz-utils \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ARG FLUTTER_VERSION=3.29.2
RUN git clone https://github.com/flutter/flutter.git -b stable /home/node/flutter && \
    chown -R node:node /home/node/flutter

USER node
RUN /home/node/flutter/bin/flutter --version && \
    /home/node/flutter/bin/flutter precache
USER root

ENV PATH="$PATH:/home/node/flutter/bin"

# ==============================================================================
# Stage 3: final
# 最終イメージ（ユーザー設定）
# ==============================================================================
FROM with-flutter AS final

# Set up non-root user
USER node

# Install global packages
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# Set the default shell to zsh rather than sh
ENV SHELL=/bin/zsh

# Set the default editor and visual
ENV EDITOR=nano
ENV VISUAL=nano

# Install zsh-in-docker with powerline10k theme
ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

# Install Claude Code
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Copy and set up firewall script and domain files
COPY init-firewall.sh /usr/local/bin/
COPY allowed-domains/ /etc/allowed-domains/

USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

USER node
