FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update -q \
    && apt-get install -y \
    autoconf \
    bison \
    build-essential \
    curl \
    file \
    gh \
    jq \
    libdb-dev \
    libffi-dev \
    libgdbm-dev \
    libreadline-dev \
    libssl-dev \
    libyaml-dev \
    tmux \
    uuid-dev \
    vim \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
ENV EDITOR=vim

# mise (system-wide)
RUN curl -sSf https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh

# Node.js + pnpm via mise (vscode user)
USER vscode
COPY --chown=vscode:vscode mise.toml /home/vscode/mise.toml
RUN cd /home/vscode && mise trust && mise install
ENV PATH="/home/vscode/.local/share/mise/shims:/home/vscode/.local/bin:$PATH"

# git-agent wrapper (GITHUB_TOKEN 認証強制)
COPY .devcontainer/git-agent /usr/local/bin/git-agent
USER root
RUN chmod +x /usr/local/bin/git-agent
USER vscode
