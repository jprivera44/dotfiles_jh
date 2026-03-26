#!/usr/bin/env bash
set -euo pipefail

# Resume tmux sessions with their exact Claude Code conversations.
# Run after RunPod restart, once runpod_setup.sh has completed.
#
# Usage:
#   bash /workspace/dotfiles_jh/runpod/resume_tmux.sh
#
# Each entry: SESSION_NAME|CONVO_ID|DESCRIPTION
# Update these when you start new long-running conversations.

PROJECT_DIR="/workspace/collusion_project_v0"

SESSIONS=(
  "data_generation|44ff1d04-202c-4378-a990-8c5c7dffd84d|MO training data evals + runpod setup"
  "re_run_training|0d911e20-a6ee-41e7-be0c-5eb22cd12916|Multi-seed prompt comparison experiment"
  "rr_data_session|8946f04a-dff5-4d20-9ad2-9b0ea230e0f1|Separability analysis + trigger zone investigation"
)

echo "=== Resuming Claude Code tmux sessions ==="
echo ""

for entry in "${SESSIONS[@]}"; do
  IFS='|' read -r sess convo_id desc <<< "$entry"

  if tmux has-session -t "$sess" 2>/dev/null; then
    echo "SKIP: '$sess' already exists"
    continue
  fi

  # Verify the conversation file exists
  convo_file="/workspace/.claude/projects/-workspace-collusion-project-v0/${convo_id}.jsonl"
  if [ ! -f "$convo_file" ]; then
    echo "WARN: '$sess' — conversation file not found: $convo_id"
    echo "      Creating session with fresh claude instead"
    tmux new-session -d -s "$sess" -c "$PROJECT_DIR" "claude"
    continue
  fi

  echo "OK:   '$sess' — $desc"
  echo "      convo: $convo_id"
  tmux new-session -d -s "$sess" -c "$PROJECT_DIR" "claude --resume $convo_id"
done

echo ""
echo "Done. Attach with:"
for entry in "${SESSIONS[@]}"; do
  IFS='|' read -r sess _ desc <<< "$entry"
  printf "  tmux attach -t %-20s  # %s\n" "$sess" "$desc"
done
