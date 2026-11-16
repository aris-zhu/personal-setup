#!/usr/bin/env bash
# personal-setup · bring a Linux box (Ubuntu desktop, reachable by ssh alias) to this setup.
#   scripts/bootstrap-linux-host.sh <ssh-host>          # e.g. opti-prod
# Pushes scripts/linux + the Claude files to <host>:~/setup and runs the user-level half there.
# The root half is one command the human runs on the host afterwards (printed at the end).
set -euo pipefail
HOST=${1:?usage: bootstrap-linux-host.sh <ssh-host>}
HERE=$(cd "$(dirname "$0")" && pwd)
STAGE=$(mktemp -d)
mkdir -p "$STAGE/linux" "$STAGE/claude"
cp "$HERE"/linux/* "$STAGE/linux/"
cp "$HERE/linux/user-tools.sh" "$HERE/linux/root-steps.sh" "$STAGE/"
cp "$HOME/.claude/CLAUDE.md" "$HOME/.claude/agents/codex-implementer.md" "$STAGE/claude/"
# claude-router (private repo, so the host cannot clone it): stage a copy. CLAUDE_ROUTER_SRC overrides
# the checkout to push (e.g. a worktree with unmerged changes).
ROUTER_SRC=${CLAUDE_ROUTER_SRC:-$HOME/personal-ws/claude-router}
if [ -d "$ROUTER_SRC" ]; then rsync -a --exclude .git --exclude node_modules "$ROUTER_SRC/" "$STAGE/claude-router/"; fi
ssh "$HOST" 'mkdir -p ~/setup'
# ~/setup is a dedicated staging directory; delete stale files from previous runs.
rsync -az --delete "$STAGE/" "$HOST:setup/"
rm -rf "$STAGE"
ssh "$HOST" 'bash ~/setup/user-tools.sh'
cat <<MSG

Next, once, on the host (needs the sudo password):
  ssh $HOST
  sudo bash ~/setup/root-steps.sh <hostname>     # apt tools, zsh as login shell, dialout/video groups, hostname, ethernet
  bash ~/setup/user-tools.sh                     # re-run: oh-my-zsh + nvim plugins now that git/zsh exist
  claude          # sign in (device/browser login)      codex login     # ChatGPT account
MSG
