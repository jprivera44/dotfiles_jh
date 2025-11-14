# Always work in /workspace
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
make setup
source .venv/bin/activate

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
uv run hf whoami || true

# --- Optional project setup
if [ -f Makefile ]; then
  make setup || true
fi
