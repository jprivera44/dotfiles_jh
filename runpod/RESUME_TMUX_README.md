# Resuming Claude Code Sessions After RunPod Restart

## Prerequisites

1. `runpod_setup.sh` has run (installs claude, sets up symlink)
2. `/workspace/.claude/` exists and has conversation history (created by the symlink: `~/.claude -> /workspace/.claude`)

## Quick Start

```bash
bash /workspace/dotfiles_jh/runpod/resume_tmux.sh
tmux attach -t data_generation
```

## How It Works

- Claude Code stores all conversation history as `.jsonl` files in `~/.claude/projects/-workspace-collusion-project-v0/`
- The symlink in `runpod_setup.sh` points `~/.claude` to `/workspace/.claude`, which lives on the persistent network volume
- `resume_tmux.sh` creates tmux sessions and runs `claude --resume <conversation-id>` in each

## Updating Sessions

Edit the `SESSIONS` array in `resume_tmux.sh`. Each entry is:

```
"SESSION_NAME|CONVERSATION_ID|DESCRIPTION"
```

## Finding Conversation IDs

If you need to find or update conversation IDs:

```bash
# List recent conversations with their first message (most recent first)
python3 -c "
import json
from pathlib import Path
from datetime import datetime

d = Path('/workspace/.claude/projects/-workspace-collusion-project-v0')
for f in sorted(d.glob('*.jsonl'), key=lambda p: p.stat().st_mtime, reverse=True)[:10]:
    first_msg = ''
    with open(f) as fh:
        for line in fh:
            obj = json.loads(line)
            if obj.get('type') == 'user':
                raw = obj.get('message', {})
                if isinstance(raw, dict):
                    first_msg = str(raw.get('content', ''))[:80]
                break
    ts = datetime.fromtimestamp(f.stat().st_mtime).strftime('%m/%d %H:%M')
    kb = f.stat().st_size // 1024
    print(f'{ts} | {kb:>5}KB | {f.stem} | {first_msg}')
"
```

Then update the `SESSIONS` array in `resume_tmux.sh` with the correct conversation ID.

## Manual Resume (if script fails)

```bash
# 1. Create a tmux session
tmux new-session -d -s my_session -c /workspace/collusion_project_v0

# 2. Attach to it
tmux attach -t my_session

# 3. Inside tmux, resume a specific conversation
claude --resume 44ff1d04-202c-4378-a990-8c5c7dffd84d

# OR just open the interactive picker to search
claude --resume
```

## Current Sessions (as of 2026-03-19)

| tmux session | conversation ID | what |
|---|---|---|
| `data_generation` | `44ff1d04-202c-4378-a990-8c5c7dffd84d` | MO training data evals, runpod setup, logprob audit |
| `my_session2` | `86d55868-66d2-4c57-adc2-efac4ad02c3f` | Data exploration |
| `rr_data_session` | `8946f04a-dff5-4d20-9ad2-9b0ea230e0f1` | Logprob audit |
