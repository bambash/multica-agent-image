FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# Layer 1 — System packages
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    openssh-client \
    ripgrep \
    tmux \
    zsh \
    less \
  && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Layer 2 — Go 1.24
# ---------------------------------------------------------------------------
ARG GO_VERSION=1.24.3
RUN curl -fsSL https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
    | tar -C /usr/local -xz
ENV PATH=/usr/local/go/bin:${PATH}

# ---------------------------------------------------------------------------
# Layer 3 — Node.js 22 LTS (via NodeSource)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Layer 4 — Python tooling (uv)
# ---------------------------------------------------------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH=/root/.local/bin:${PATH}

# ---------------------------------------------------------------------------
# Layer 5 — OpenBao CLI (bao) — Vault-compatible secrets manager
# ---------------------------------------------------------------------------
ARG BAO_VERSION=2.5.3
RUN curl -fsSLO "https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/openbao_${BAO_VERSION}_linux_amd64.deb" \
  && dpkg -i "openbao_${BAO_VERSION}_linux_amd64.deb" \
  && rm "openbao_${BAO_VERSION}_linux_amd64.deb" \
  && bao version

# ---------------------------------------------------------------------------
# Layer 6 — GitHub CLI (gh)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/* \
  && gh --version

# ---------------------------------------------------------------------------
# Layer 7 — Multica daemon CLI
# The installer tries /usr/local/bin first (writable as root), so the binary
# lands at /usr/local/bin/multica.
# ---------------------------------------------------------------------------
RUN curl -fsSL https://raw.githubusercontent.com/multica-ai/multica/main/scripts/install.sh | bash \
  && multica --version

# ---------------------------------------------------------------------------
# Layer 8 — Claude Code (npm global install, lands in /usr/lib/node_modules
# with a symlink at /usr/bin/claude or /usr/local/bin/claude)
# ---------------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# ---------------------------------------------------------------------------
# Layer 9 — Non-root user (UID 1001)
# All tools installed globally above remain accessible on system PATH.
# ---------------------------------------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set PATH for agent user before switching — node globals (/usr/bin),
# multica (/usr/local/bin), and go (/usr/local/go/bin) are all on system PATH.
ENV PATH=/home/agent/.local/bin:/usr/local/bin:/usr/local/go/bin:/usr/bin:/bin:${PATH}
ENV HOME=/home/agent

RUN useradd -m -u 1001 -s /bin/bash agent

USER agent
WORKDIR /home/agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]