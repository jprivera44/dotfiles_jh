#!/usr/bin/env bash
set -euo pipefail


# Always work in /workspace
cd /workspace

# --- Persist Claude Code state on network volume ---
mkdir -p /workspace/.claude
ln -sfn /workspace/.claude ~/.claude

# --- Install zsh and dotfiles first ---
cd /workspace/dotfiles_jh
git checkout jprivera-config || true
./install.sh --tmux --zsh
# Now go back to workspace
cd /workspace



# --- Your repo (SSH clone). Do NOT cd before cloning.
if [ ! -d "collusion-monitors" ]; then
  git clone git@github.com:jprivera44/collusion-monitors.git collusion-monitors
fi
cd /workspace/collusion-monitors

# Make sure branch exists locally
git fetch --all --prune || true
git checkout initial-setup || true

# --- Hugging Face: keep everything in /workspace
export HF_HOME="/workspace/hf"
export TRANSFORMERS_CACHE="/workspace/hf/transformers"
export HF_DATASETS_CACHE="/workspace/hf/datasets"
mkdir -p "$HF_HOME" "$TRANSFORMERS_CACHE" "$HF_DATASETS_CACHE"
chmod 700 "$HF_HOME"

# --- Ensure uv is available (only if it's not already installed earlier)
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  . "$HOME/.local/bin/env"
fi

# --- Create/refresh the project venv and deps
# uv sync creates .venv based on pyproject/uv.lock
#wrap below in if statement to not run make setup again
if [ -d ".venv" ]; then
  source .venv/bin/activate
else
  make setup
  source .venv/bin/activate
fi

# Make sure the HF CLI is present inside the venv (so we can use `hf`)
uv run pip install -U huggingface_hub

# --- Non-interactive login with the new CLI (force `hf`)
if [ -n "${HUGGINGFACE_HUB_TOKEN:-}" ]; then
  # also write token under HF_HOME (avoids ~/.cache)
  printf "%s" "$HUGGINGFACE_HUB_TOKEN" > "$HF_HOME/token"
  chmod 600 "$HF_HOME/token"

  # login via uv-run so we don't need to activate .venv
  uv run hf auth login --token "$HUGGINGFACE_HUB_TOKEN" --add-to-git-credential
fi

# sanity (won’t print your token)
uv run hf auth whoami || true


#now running the set up commands
if [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 1) Put brew on *this* shell's PATH now
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 2) Make it persist for future shells (login + interactive zsh)
grep -q 'brew shellenv' ~/.zprofile || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zprofile
grep -q 'brew shellenv' ~/.zshrc    || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc

echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"' >> ~/.zshrc


# 3) Install Claude Code if missing
brew list --cask claude-code >/dev/null 2>&1 || brew install --cask claude-code

#source ~/.zshrc

# 4) Sanity checks
command -v brew
command -v claude
claude --version

# Configure Git identity
git config --global user.email "jprivera44@gmail.com"
git config --global user.name "jprivera44"

echo "Git configured: $(git config --global user.name) <$(git config --global user.email)>"

