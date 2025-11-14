
cd ..
./install.sh --tmux --zsh || true
./deploy.sh || true

cd /workspace

cd collusion monitors
# 2) Your repo
if [ ! -d "collusion-monitors" ]; then
  # Pick ONE method. If repo is private, use SSH and connect with agent forwarding.
  git clone git@github.com:jprivera44/collusion-monitors.git collusion-monitors 
   
fi
cd /workspace/collusion-monitors


cd /workspace/collusion-monitors
git fetch --all --prune || true
git checkout initial-setup || true


uv run pip install -U huggingface_hub >/dev/null 2>&1 || true

# Put all HF files under /workspace/hf
export HF_HOME="/workspace/hf"
export TRANSFORMERS_CACHE="/workspace/hf/transformers"
export HF_DATASETS_CACHE="/workspace/hf/datasets"

# Make sure the dirs exist and perms are safe
mkdir -p "$HF_HOME" "$TRANSFORMERS_CACHE" "$HF_DATASETS_CACHE"
chmod 700 "$HF_HOME"

# Install CLI (if not already)
uv run pip install -U "huggingface_hub"

source .venv/bin/activate

# Non-interactive login using your template env var
if [ -n "${HUGGINGFACE_HUB_TOKEN:-}" ]; then
  # Write the token to HF_HOME (not ~/.cache)
  printf "%s" "$HUGGINGFACE_HUB_TOKEN" > "$HF_HOME/token"
  chmod 600 "$HF_HOME/token"

  # Also register the token with the CLI + git credential helper
  hf auth login --token "$HUGGINGFACE_HUB_TOKEN" --add-to-git-credential
fi

# Quick sanity check (won't print your token)
huggingface-cli whoami || true

# 4) optional: run your project setup if Makefile exists
if [ -f Makefile ]; then
  make setup || true
fi