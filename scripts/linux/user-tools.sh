#!/usr/bin/env bash
# personal-setup · Linux host, USER-LEVEL half (no sudo). Idempotent — re-run any time.
# Runs ON the host from ~/setup, where scripts/bootstrap-linux-host.sh pushes it from the Mac.
#
#   1. static curl in ~/.local/bin — Ubuntu desktop ships only the snap curl, which cannot write
#      into dot-directories, so every `curl | sh` installer (Claude Code, uv, mise) breaks without it
#   2. uv + CPython 3.12 (the robot venvs pin 3.12; the system python is 3.14)
#   3. mise + node LTS (npm is what installs the Codex CLI)
#   4. Claude Code (native installer) + Codex CLI; Codex registered as Claude's user-scoped MCP
#      server; ~/.claude/CLAUDE.md and the codex-implementer agent copied from the Mac
#   5. dotfiles: ~/.zshrc ~/.zshenv ~/.config/nvim/{init.lua,lazy-lock.json}; PATH + mise in ~/.bashrc
#   6. claude-router + shell integration
#   7. GitHub token helper
#   8. once git and zsh exist (root-steps.sh): oh-my-zsh with --keep-zshrc, then `Lazy! restore`
#
# Signing in is the one thing left to a human:  claude   (browser/device login)   and   codex login
set -euo pipefail
SETUP=${SETUP:-$HOME/setup}
BIN=$HOME/.local/bin
CURL_VER=8.22.0            # github.com/stunnel/static-curl
UV_VER=0.12.17             # github.com/astral-sh/uv
MISE_VER=v2026.9.12        # github.com/jdx/mise
mkdir -p "$BIN" "$HOME/.config/nvim" "$HOME/.claude/agents"
export PATH="$BIN:$PATH"
export MISE_YES=1   # never prompt: this runs over ssh
log() { printf '\n== %s\n' "$*"; }
fetch() {  # fetch <url> <dest> — wget is apt-installed on Ubuntu desktop; python3 is the fallback
  if command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"; else
    python3 -c 'import sys,urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])' "$1" "$2"; fi
}

log "1/8 static curl $CURL_VER (musl build)"
# Only a stopgap until root-steps.sh installs apt's curl; once that exists, drop the static copy.
if [ -x /usr/bin/curl ] && /usr/bin/curl -fsS -o /dev/null https://github.com/ 2>/dev/null; then
  rm -f "$BIN/curl"; echo "apt curl present; static curl removed"
elif true; then
# The glibc static build dies with a floating-point exception on the first TLS request on these
# OptiPlex boxes (Ubuntu 26.04, kernel 7.0); the musl build works. The check is functional, not a
# version string, so a crashing binary gets replaced.
if ! [ -x "$BIN/curl" ] || ! "$BIN/curl" -fsS -o /dev/null https://github.com/ 2>/dev/null; then
  tmp=$(mktemp -d)
  fetch "https://github.com/stunnel/static-curl/releases/download/$CURL_VER/curl-linux-x86_64-musl-$CURL_VER.tar.xz" "$tmp/curl.tar.xz"
  tar -xJf "$tmp/curl.tar.xz" -C "$tmp"
  install -m 755 "$(find "$tmp" -type f -name curl | head -1)" "$BIN/curl"; rm -rf "$tmp"
fi
fi
curl --version | head -1

log "2/8 uv $UV_VER + python 3.12"
if ! [ -x "$BIN/uv" ]; then
  tmp=$(mktemp -d)
  fetch "https://github.com/astral-sh/uv/releases/download/$UV_VER/uv-x86_64-unknown-linux-gnu.tar.gz" "$tmp/uv.tgz"
  tar -xzf "$tmp/uv.tgz" -C "$tmp"
  install -m 755 "$tmp"/uv-*/uv "$tmp"/uv-*/uvx "$BIN/"; rm -rf "$tmp"
fi
uv --version
uv python install 3.12

log "3/8 mise $MISE_VER + node LTS"
if ! [ -x "$BIN/mise" ]; then
  fetch "https://github.com/jdx/mise/releases/download/$MISE_VER/mise-$MISE_VER-linux-x64" "$BIN/mise"; chmod 755 "$BIN/mise"
fi
mise --version
mise use -g node@lts gh@latest
eval "$(mise activate bash --shims)"
node --version; npm --version

log "4/8 Claude Code + Codex CLI"
command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
claude --version
npm install -g @openai/codex@latest >/dev/null
codex --version
# Codex as Claude's MCP server, user scope (same registration as the Mac — see ~/personal-ws/codex-setup)
claude mcp remove -s user codex >/dev/null 2>&1 || true
claude mcp add --scope user --transport stdio codex -- codex mcp-server -c 'approval_policy="never"' -c 'sandbox_mode="workspace-write"'
cp "$SETUP/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
cp "$SETUP/claude/codex-implementer.md" "$HOME/.claude/agents/codex-implementer.md"

log "5/8 dotfiles"
put() {  # put <src> <dst> — first install only; a hand-maintained file is never overwritten
  if [ -e "$2" ] && ! cmp -s "$1" "$2"; then echo "kept $2 (differs from $1)"; else cp "$1" "$2"; echo "wrote $2"; fi
}
put "$SETUP/linux/zshrc" "$HOME/.zshrc"
put "$SETUP/linux/zshenv" "$HOME/.zshenv"
put "$SETUP/linux/init.lua" "$HOME/.config/nvim/init.lua"
put "$SETUP/linux/lazy-lock.json" "$HOME/.config/nvim/lazy-lock.json"
if ! grep -q 'personal-setup' "$HOME/.bashrc"; then cat >> "$HOME/.bashrc" <<'RC'

# personal-setup: user-level tools (static curl, uv, mise, claude, codex); zsh is the real shell
export PATH="$HOME/.local/bin:$PATH"
[ -x "$HOME/.local/bin/mise" ] && eval "$("$HOME/.local/bin/mise" activate bash)"
RC
fi

log "6/8 claude-router (account router: \`claude\` picks the subscription by usage limits)"
if [ -d "$SETUP/claude-router" ]; then
  mkdir -p "$HOME/personal-ws/claude-router"
  if [ -e "$HOME/personal-ws/claude-router/.git" ]; then
    echo "claude-router is a git checkout; skipping sync. Update it with git."
  else
    rsync -a --delete "$SETUP/claude-router/" "$HOME/personal-ws/claude-router/"
  fi
  chmod +x "$HOME/personal-ws/claude-router/claude-router.mjs" "$HOME/personal-ws/claude-router/claude-launch.zsh"
  ln -sfn "$HOME/personal-ws/claude-router/claude-router.mjs" "$BIN/claude-router"
  ln -sfn "$HOME/personal-ws/claude-router/claude-launch.zsh" "$BIN/claude-routed"
  # statusLine + the three hook events the launcher needs, merged into ~/.claude/settings.json (idempotent)
  python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
d = json.load(open(p)) if os.path.exists(p) else {}
d["statusLine"] = {"type": "command", "command": "claude-router statusline"}
hooks = d.setdefault("hooks", {})
for event, timeout in (("Stop", 10), ("StopFailure", 10), ("UserPromptSubmit", 5)):
    rows = hooks.setdefault(event, [])
    if not any("claude-router hook" in h.get("command", "") for r in rows for h in r.get("hooks", [])):
        rows.append({"hooks": [{"type": "command", "command": "claude-router hook", "timeout": timeout}]})
tmp = p + ".tmp"; json.dump(d, open(tmp, "w"), indent=2); open(tmp, "a").write("\n"); os.replace(tmp, p)
PY
  # shellcheck disable=SC2016 # Write literal shell code for evaluation when zsh starts.
  grep -q "claude-router shell-init" "$HOME/.zshrc" 2>/dev/null || printf '\n# Claude Code account router (~/personal-ws/claude-router): `claude` picks the account by usage limits\ncommand -v claude-router >/dev/null && eval "$(claude-router shell-init)"\n' >> "$HOME/.zshrc"
  echo "claude-router installed: $(claude-router list 2>&1 | head -1)"
else
  echo "no claude-router in ~/setup (bootstrap from the Mac stages it); skipped"
fi

log "7/8 GitHub token hook-up (the token itself is placed by hand, one per machine)"
# Put the machine's fine-grained PAT at ~/.config/github/token (0600). git then reads it through this
# helper for private clones/pushes; nothing copies the secret into a second store. For gh use
# GH_TOKEN=$(cat ~/.config/github/token), or run `gh auth login --with-token < ~/.config/github/token` yourself.
if command -v git >/dev/null 2>&1; then
  # Remove only the exact legacy helper; preserve any independently configured helpers.
  legacy_helper_status=0
  # shellcheck disable=SC2016 # Match the literal legacy helper, not shell expansions.
  git config --global --unset-all credential.helper '^!f\(\) \{ echo username=aris-zhu; echo "password=\$\(cat ~/\.config/github/token\)"; \}; f$' 2>/dev/null || legacy_helper_status=$?
  case "$legacy_helper_status" in
    0) echo "removed legacy unscoped credential.helper" ;;
    5) ;; # No exact legacy helper was configured.
    *) echo "WARNING: could not remove legacy credential.helper (exit $legacy_helper_status); check manually: git config --global --get-all credential.helper" ;;
  esac
  # shellcheck disable=SC2016 # Keep the helper literal until Git invokes it.
  git config --global credential.https://github.com.helper '!f() { if [ "$1" = get ] && [ -s "$HOME/.config/github/token" ]; then printf "username=aris-zhu\npassword=%s\n" "$(cat "$HOME/.config/github/token")"; fi; }; f'
else
  echo "git not installed yet: the GitHub helper is set when this script is re-run after root-steps.sh"
fi
[ -s "$HOME/.config/github/token" ] && echo "token file present" || echo "no ~/.config/github/token yet: create it (0600) when this machine gets its own PAT"

log "8/8 shell + editor"
if command -v git >/dev/null 2>&1 && command -v zsh >/dev/null 2>&1; then
  if ! [ -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  fi
  echo "oh-my-zsh in place"
  if command -v nvim >/dev/null 2>&1; then
    restore_status=0
    nvim --headless "+Lazy! restore" +qa 2>&1 || restore_status=$?
    if [ "$restore_status" -eq 0 ]; then
      echo "nvim plugin restore completed"
    else
      echo "WARNING: nvim plugin restore failed (exit $restore_status); run nvim, then :Lazy restore manually."
    fi
  else
    echo "nvim not installed; plugin restore skipped"
  fi
else
  echo "git/zsh not installed yet: run   sudo bash ~/setup/root-steps.sh <hostname>   then re-run this script"
fi
echo "The nvim config enables TypeScript and Lua language servers; this script does not install them."
echo; echo "done: $(claude --version 2>/dev/null) · $(codex --version 2>/dev/null) · uv $(uv --version | cut -d' ' -f2) · node $(node --version)"
