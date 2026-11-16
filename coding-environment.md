# Coding Environment

A replicable description of the current Neovim + zsh setup, including plugins, keybindings, and external dependencies.

## Overview

| Layer | Tool | Notes |
|---|---|---|
| Editor | **Neovim 0.12.4** (LuaJIT 2.1) | config at `~/.config/nvim/` |
| Plugin manager | **lazy.nvim** (self-bootstrapping) | lockfile pins exact commits |
| Shell | **zsh** + **oh-my-zsh**, theme `gallifrey` | no extra omz plugins enabled |
| Version mgr | **mise** + **conda** (anaconda3) | both auto-activated in `.zshrc` |

`$EDITOR=nvim`, and `vim` is aliased to `nvim`.

## Neovim — `~/.config/nvim/init.lua`

A single self-contained `init.lua` (a "superset of the old `.vimrc`"). Structure: leader → options → keymaps → plugin bootstrap → plugins.

**Leader key:** `<Space>` (both `mapleader` and `maplocalleader`).

### Options
- `number`, `cursorline`, `termguicolors`, `mouse=a`
- `clipboard=unnamedplus` (system clipboard)
- 4-space indent: `tabstop=4`, `shiftwidth=4`, `expandtab`
- `ignorecase` + `smartcase`
- `wildmenu` / `wildmode=full`

### Keymaps

| Mode | Key | Action |
|---|---|---|
| insert | `jk` | escape to normal mode |
| normal | `<C-p>` | Telescope find_files (fuzzy file finder) |
| normal | `gh` | Telescope live_grep |
| normal | `<leader>g` / `<leader>fg` | Telescope live_grep |
| normal | `<C-n>` | toggle nvim-tree file explorer |
| normal | `gcc` / `gc` | comment line/selection (Comment.nvim) |
| insert | `<Tab>` / `<S-Tab>` | cycle completion menu (supertab-style) |
| insert | `<CR>` | confirm completion |

**LSP keymaps** — buffer-local, active only once a language server attaches (so `gd` keeps its
built-in "local declaration" meaning in files with no LSP). Code navigation goes through Telescope
pickers: a single result jumps straight there, multiple results open a fuzzy-searchable list.

| Mode | Key | Action |
|---|---|---|
| normal | `gd` | go to definition |
| normal | `gr` | list references ("everywhere this is used") |
| normal | `gy` | go to type definition |
| normal | `<leader>gi` | list implementations |
| normal | `<leader>rn` | rename symbol (project-wide) |
| normal | `<leader>ca` | code action |
| normal | `K` | hover docs (Neovim built-in default) |
| normal | `[d` / `]d` | previous / next diagnostic (built-in default) |

#### Why the built-in `gr*` maps are deleted

Neovim 0.11+ ships its own LSP defaults on a **`gr` prefix**: `grn` (rename), `gra` (code action),
`grr` (references), `gri` (implementation), `grt` (type def), `grx`. Leaving those mapped makes a
bare `gr` ambiguous — Neovim can't know whether you're done typing or about to add another `r`, so
it sits and waits out `timeoutlen` (~1s) before firing.

`init.lua` therefore deletes all six defaults (in a `pcall` loop, since older versions don't define
them) so `gr` fires instantly, and re-homes the two genuinely useful ones on `<leader>rn` /
`<leader>ca`. If a future `gr`-prefixed default is added upstream and `gr` starts feeling laggy
again, add it to that delete list.

### Plugins

6 user plugins + dependencies, all commit-pinned in `lazy-lock.json`:

- `telescope.nvim` (branch `0.1.x`) + `plenary.nvim` — fuzzy find & grep
- `nvim-tree.lua` + `nvim-web-devicons` — file tree, 35-col width, `group_empty=true`
- `Comment.nvim` — `gcc`/`gc` commenting
- `nvim-cmp` + `cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`, `LuaSnip`, `cmp_luasnip` — completion
- `nvim-lspconfig` — LSP client configs; supplies the server `cmd` / `filetypes` / root-marker
  detection that `gd`/`gr` rely on

### LSP

Servers are enabled via `vim.lsp.enable({ "ts_ls", "lua_ls" })` (Neovim 0.11+ API — `nvim-lspconfig`
ships the definitions, Neovim starts them). `cmp-nvim-lsp` advertises nvim-cmp's completion
capabilities to every server via `vim.lsp.config("*", ...)`, which is what routes LSP completions
into the existing `<Tab>` menu.

| Server | Language | Root markers |
|---|---|---|
| `ts_ls` | TypeScript / JS / TSX | `tsconfig.json`, `package.json`, `.git` |
| `lua_ls` | Lua (the nvim config itself) | `.luarc.json`, `.git` |

`lua_ls` is configured for `LuaJIT`, told `vim` is a global (it's injected by the editor, not
declared), and pointed at the Neovim runtime so `gd` works on Neovim's own API functions.

Two servers, because that's what this machine actually writes: TypeScript projects and this
`init.lua`. Adding another is one entry in `vim.lsp.enable` plus installing its binary.

### Custom autocmd

Auto-saves `.zshrc` / `.zprofile` / `.zshenv` on `InsertLeave`/`TextChanged` while editing them.

### External CLI dependencies

Telescope needs these (all currently installed):

- `ripgrep` 15.1.0 (`rg`, **required** for live_grep)
- `fd` 10.4.2 (find_files)
- `git` (used by lazy.nvim to clone plugins)
- A **Nerd Font** in the terminal for nvim-web-devicons icons to render — see
  [Terminal font (iTerm2)](#terminal-font-iterm2--meslo-nerd-font)

The language servers are plain binaries on `PATH` — Neovim spawns them, nothing auto-installs them:

- `typescript-language-server` 5.3.0 (npm, global) — powers `gd`/`gr` in TS/JS
- `typescript` 5.9.3 (npm, global) — see the pin note below
- `lua-language-server` 3.18.2 (brew)

> **Pin global `typescript` to 5.x — not `latest`.**
> `typescript-language-server` doesn't bundle TypeScript; it locates one, preferring the workspace's
> `node_modules/typescript` and falling back to the global install for files in projects that have
> none. As of TypeScript **7.x** (the native rewrite) the package no longer ships `lib/tsserver.js`,
> which is exactly what the language server looks for. A bare `npm i -g typescript` installs 7.x and
> `ts_ls` then dies on startup with *"Could not find a valid TypeScript installation"* — in projects
> without local TypeScript only, which makes it look intermittent. Hence `typescript@5.9.3`.
> Projects with their own TypeScript are unaffected either way, since the workspace copy wins.

## Shell — `~/.zshrc`

- oh-my-zsh, `ZSH_THEME="gallifrey"`, no `plugins=(...)` array (stock omz only)
- `.zshenv` just sources `~/.cargo/env`

**Git branch in prompt:** the `gallifrey` theme shows the current branch on the right-hand side of the prompt (rendered asynchronously, so it appears a beat after the prompt draws). `.zshrc` also contains a self-contained `vcs_info` fallback that draws `(branch)` inline — it's guarded by `if ! typeset -f git_prompt_info` so it **only activates when oh-my-zsh isn't loaded**; once omz/gallifrey is present, the theme drives the branch and the fallback disables itself.

**Prompt label is `AZ`.** The prompt reads `AZ ~ »`. `.zshrc` re-defines `PROMPT` *after* sourcing omz, substituting a short fixed label for the one gallifrey opens with and keeping the rest of the theme's prompt verbatim (`%2~` dir, git slot, bold `»`, red-when-root):

```zsh
if typeset -f git_prompt_info > /dev/null; then
    PROMPT="%(!.%{$fg[red]%}.%{$fg[green]%})AZ%{$reset_color%} %2~ \$(git_prompt_info)%{$reset_color%}%B»%b "
fi
```

The `typeset -f` guard means it only applies when omz actually loaded. This is a prompt-only change — no system settings are touched.

**No `(base)` prefix — conda does not auto-activate.** A stock Anaconda install activates its `base` env in every new shell, so the prompt reads `(base) AZ ~ »`. That's turned off in `~/.condarc`:

```yaml
auto_activate: false
```

(The key was called `auto_activate_base` before conda 25.x; on current conda it's `auto_activate`.) Conda stays on `PATH` and works normally — you just aren't *in* an env until you ask, via the `cab` alias. `(base)` reappearing is then a real signal that base is active rather than constant noise.

Two consequences worth knowing:
- **Bare `python` is Homebrew's, not Anaconda's,** in a fresh shell. Run `cab` first if you want Anaconda's interpreter.
- `conda deactivate` takes **no argument** — `conda deactivate base` is an error (`ArgumentError: deactivate does not accept arguments`). It's also only per-shell; the `.condarc` setting above is the durable fix.

**Aliases:**
- `vim=nvim`
- `vimrc=nvim ~/.config/nvim/init.lua` — edit the Neovim config
- `zshrc='nvim ~/.zshrc && source ~/.zshrc'` — edit `~/.zshrc`, then auto-reload it into the current shell on quit (a shell can't reload its own parent, so the `source` runs after nvim exits)
- `szsh='source ~/.zshrc'` — just reload `~/.zshrc` into the current shell without editing (handy after changing it elsewhere)
- `nb=jupyter notebook`
- `cab='conda activate base'`
- `keepawake='~/.local/bin/keepawake'` — toggle display-sleep prevention (see [Keeping the Mac awake](#keeping-the-mac-awake--keepawake))

**PATH/env:** homebrew python/ruby, `~/.local/bin`, `~/.cargo/bin`, conda init block, `eval "$(~/.local/bin/mise activate)"`, `OPENSSL_ROOT_DIR`, Docker bin, `postgresql@16` bin.

## Replication steps (fresh macOS)

```bash
# 1. Core tools  (macOS: brew | Ubuntu/Debian: sudo apt install neovim ripgrep fd-find git zsh)
brew install neovim ripgrep fd git

# 1a. Language servers for gd / gr (see the "Pin global typescript to 5.x" note above —
#     `typescript@5`, NOT bare `typescript`, which now resolves to the 7.x native rewrite
#     that ts_ls can't drive).
brew install lua-language-server
npm install -g typescript-language-server typescript@5

# 1b. oh-my-zsh — install WITHOUT overwriting the hand-maintained ~/.zshrc.
#     --keep-zshrc preserves it; --unattended skips the chsh prompt.
RUNZSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended --keep-zshrc

# 2. Drop in configs (copy these files from this machine)
#   ~/.config/nvim/init.lua
#   ~/.config/nvim/lazy-lock.json   <- keeps exact plugin versions
#   ~/.zshrc   (ZSH_THEME="gallifrey"; already sources omz + the vcs_info branch
#               fallback + the AZ prompt override)
#   ~/.zshenv

# 3. First nvim launch bootstraps lazy.nvim and installs all plugins.
#    To get byte-identical plugin versions:
nvim --headless "+Lazy! restore" +qa     # restores commits from lazy-lock.json

# 4. If Anaconda is installed: stop it auto-activating base in every shell,
#    which is what puts the "(base)" prefix on the prompt.
conda config --set auto_activate false   # pre-25.x conda: auto_activate_base

# 5. Sanity-check the LSP wiring: open a .ts file inside a real project and run
#    :checkhealth vim.lsp   -> ts_ls should be listed as attached.
#    If it isn't, :LspLog is the first place to look (the TypeScript 7.x trap above
#    surfaces there as "Could not find a valid TypeScript installation").
```

Install a Nerd Font for the file-tree icons — see
[Terminal font (iTerm2)](#terminal-font-iterm2--meslo-nerd-font). `mise`, `conda`, Docker, and
`postgresql@16` are referenced in `.zshrc` but are optional unless you need those toolchains.

The whole nvim setup is still just two files (`init.lua` + `lazy-lock.json`, ~9KB total) — copy them plus `ripgrep`/`fd` and the language-server binaries from step 1a, and you've reproduced the editor exactly.

## Linux hosts — `opti-dev` / `opti-prod` (Ubuntu desktop, over Tailscale)

Two Dell OptiPlex boxes run the SO-101 rigs. **`opti-dev`** (the original "optiplex") is the
development rig host; **`opti-prod`** (reached through Tailscale SSH — no keys to copy) is the host that livestreams every
live rig to the arena. Both are Ubuntu 26.04 desktop installs: 16 cores, 14 GB, no GPU, the
system python is 3.14, and `eno1` stays DOWN until a cable is in (they boot onto a Wi-Fi dongle).

On the Mac, `~/.ssh/config` names them (`Host opti opti-dev` and `Host opti-prod opti2`, by
Tailscale IP so a hostname change never breaks them; the IPs live only there, not in
this public repo) and `.zshrc` has `sshopti` / `sshoptidev` and `sshopti2` /
`sshoptiprod`.

### Bootstrap — two halves

```bash
# 1. USER half, run from the Mac: pushes scripts/linux + ~/.claude/{CLAUDE.md,agents/codex-implementer.md}
#    to <host>:~/setup and runs user-tools.sh there. No sudo. Idempotent — re-run any time.
scripts/bootstrap-linux-host.sh opti-prod

# 2. ROOT half, once, on the host (the only step that needs the sudo password):
ssh opti-prod
sudo bash ~/setup/root-steps.sh opti-prod     # apt: git zsh neovim ripgrep fd-find curl wget rsync build-essential v4l-utils
                                              # chsh → zsh; groups dialout (arms) + video (cameras); hostname (+ tailnet name);
                                              # ethernet ahead of Wi-Fi (the nmcli metric fix opti-dev needed on 2026-09-15)
bash ~/setup/user-tools.sh                    # re-run: oh-my-zsh (--keep-zshrc) + `Lazy! restore` now that git/zsh exist
claude            # sign in (device/browser login)
codex login       # ChatGPT account
```

`user-tools.sh` installs, in order: a **static curl** into `~/.local/bin`, **uv** + CPython 3.12,
**mise** + node LTS, **Claude Code** (native installer) and the **Codex CLI** (`npm -g`), registers
Codex as Claude's user-scoped MCP server exactly as `~/personal-ws/codex-setup` describes, and
drops the dotfiles. The first-install versions of curl, uv and mise are pinned at the top of the script (`CURL_VER`, `UV_VER`, `MISE_VER`); an existing install is kept as is, and node, gh and Codex track their latest releases.

**Why the static curl comes first.** Ubuntu desktop ships *only* the snap build of curl, and a
snap cannot write into dot-directories (`~/.local`, `~/.cache`, `~/.claude`), so every
`curl … | sh` installer — Claude Code's, uv's, mise's — fails in odd ways. `user-tools.sh` fetches
the first binaries with `wget`/`python3` instead and puts a real curl ahead of `/snap/bin` on
`PATH`; `root-steps.sh` later swaps the snap for apt's curl. Use the **musl** build of
[stunnel/static-curl](https://github.com/stunnel/static-curl): the glibc build dies with a
floating-point exception on its first TLS request on these boxes (seen 2026-09-21 on opti-prod).
The snap curl has one more side effect: it prints a multi-line "Caution" banner on **stderr** for
every call, which breaks any remote command that merges stderr (the robot orchestrator's rig health
check over ssh read an empty line and marked every rig offline). `curl.snap-acked` silences the
banner; removing the snap (`root-steps.sh` does) removes the problem. The same snap confinement is why uv is
installed from its release tarball rather than `astral.sh/uv/install.sh`.

**Dotfiles differ from the Mac's on purpose.** `scripts/linux/zshrc` is the Linux `.zshrc` (same
structure as the Mac's: omz `gallifrey`, the `vcs_info` fallback, the prompt override — but the
label is `%n@%m`, so a remote shell reads `aris@opti-prod ~ »` and always says which box it is).
`scripts/linux/init.lua` + `lazy-lock.json` are the Linux copies of the Neovim config (the same
setup described above, with the plugin commits the Linux boxes were restored from). `user-tools.sh`
never overwrites a dotfile that already differs on the host — they are hand-maintained there too.

**claude-router comes along.** The bootstrap stages `~/personal-ws/claude-router` (a private repo,
so the host cannot clone it) and `user-tools.sh` installs it the way its README says: symlinks
`claude-router` and `claude-routed` into `~/.local/bin`, merges the `statusLine` and the three hook
events into `~/.claude/settings.json`, and adds the `shell-init` line to `.zshrc`. On Linux the
router keeps each slot's credentials in `<slot>/.credentials.json` instead of the Keychain (see the
router README's Linux paragraph). Enrolling is per machine: run `claude-router add <email>` for each
account on the host itself; refresh tokens rotate, so never copy a credentials file between
machines. To push a checkout other than the main one, set `CLAUDE_ROUTER_SRC=<dir>`.

**Sign-ins stay manual** (`claude-router add <email>` per account, `codex login`): both are
browser/device logins tied to the user's accounts. Everything else is unattended.

**GitHub access is one fine-grained token per machine**, kept only on that machine at
`~/.config/github/token` (0600) and placed by hand. `user-tools.sh` installs `gh` via mise and sets a
git credential helper that reads that file, so private clones and pushes work without copying the
secret anywhere else. When creating the token on github.com, set *Repository access → Only select
repositories* to the private repos the box needs and *Contents: Read* (Read and write for pushes);
a token left on "Public repositories" authenticates fine but every private repo answers 404, which
looks like a wrong token.

### Rig software (not part of this repo)

The rig daemon and its host scripts are deployed from the `so101-mujoco` repo, branch
`live-rigs/rigd-deploy`: `rigd/deploy/deploy-host.sh <host> --ffmpeg <dir>` rsyncs `rigd/` to
`~/robot-run`, builds the venv at `~/so101/venv` (Python 3.12: numpy, OpenCV, Pillow, pyserial;
`--arms` adds LeRobot 0.6.2 on a CPU torch) and seeds a fake `rigs.json`. The Mac-side stack that
points the arena at `opti-prod` lives in `~/my-ws/serve2/opti-prod-stack/` (`stack.sh start|stop|status`).

## Terminal font (iTerm2) — Meslo Nerd Font

The "icons" in nvim (nvim-tree / nvim-web-devicons) aren't images — they're glyphs in a **Nerd
Font**'s private-use area. With an unpatched font (the profile originally used Monaco) iTerm2 has no
glyph to draw and falls back to the `?` box.

Two pieces:

- **Font:** the `font-meslo-lg-nerd-font` Homebrew cask, which installs the Meslo LG Nerd Font
  family into `~/Library/Fonts`. The profile uses **MesloLGS Nerd Font Mono**
  (PostScript name `MesloLGSNFM-Regular`, size 16). *Mono* = icons scaled to exactly one terminal
  cell, so nothing overlaps or clips in nvim; the non-Mono variant draws larger icons that can bleed
  into the next cell. *LGS* = small line gap, the variant closest to Monaco's feel (and the one
  powerlevel10k standardised on).
- **Profile:** a **dynamic profile** at
  `~/Library/Application Support/iTerm2/DynamicProfiles/nerd-font.json`
  (repo copy: `scripts/iterm2-nerd-font-profile.json`). Via `Dynamic Profile Parent Name` it
  inherits everything from the `Default` profile and overrides only `Normal Font`.

**Why a dynamic profile instead of editing the Default profile directly:** iTerm2 holds its settings
in memory and rewrites `com.googlecode.iterm2.plist` from memory on quit, so a `defaults write` /
PlistBuddy edit made while it's running is silently discarded. The `DynamicProfiles/` folder is the
supported automation path — iTerm2 watches it and loads changes live, no restart needed.

**Flipping already-open sessions:** an open tab stays on its old profile until told otherwise.
iTerm2's proprietary `SetProfile` escape sequence switches a session live when written to that
session's tty (hook stdout / a pipe won't do — it must reach the terminal device, same trick as
`tab-color.sh`):

```bash
printf '\033]1337;SetProfile=Default (Nerd Font)\a' > /dev/ttysNNN
```

**One step stays manual:** a dynamic profile can't make itself the default, so *new* windows/tabs
keep opening with `Default` (Monaco) until it's set in the GUI — *Settings → Profiles → select
"Default (Nerd Font)" → Other Actions… → Set as Default*.

### Replication (fresh macOS + iTerm2)

```bash
brew install --cask font-meslo-lg-nerd-font

mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
cp scripts/iterm2-nerd-font-profile.json \
   "$HOME/Library/Application Support/iTerm2/DynamicProfiles/nerd-font.json"

# Flip every currently-open session to it (new ones need the Set as Default step above)
for t in $(ps -A -o tty= | grep -E '^ttys' | sort -u); do
  printf '\033]1337;SetProfile=Default (Nerd Font)\a' > /dev/$t 2>/dev/null
done
```

The JSON assumes the parent profile is named `Default` — adjust `Dynamic Profile Parent Name` if
yours differs. Font size lives in the same string (`"MesloLGSNFM-Regular 16"`). To try the larger
non-Mono icons instead, swap in `MesloLGSNF-Regular`.

## Screenshots (macOS) — `fn+F4`

On the Mac, **`fn+F4`** captures the full screen straight to a file in `~/screenshots`. This overrides F4's stock behaviour (Spotlight/Launchpad).

It's built entirely from macOS's own hotkey table — no Hammerspoon/skhd, no extra app:

| Setting | Value | Why |
|---|---|---|
| `com.apple.screencapture` `location` | `~/screenshots` | where captures land (default is the Desktop) |
| `com.apple.symbolichotkeys` id **28** | `F4`, no modifiers | id 28 is *"Save picture of screen as a file"* (stock `⌘⇧3`) |
| `NSGlobalDomain com.apple.keyboard.fnState` | `false` | keeps the top row as media keys — see below |

**Why `fnState` matters, and why it's `false` here.** The top row is either media keys or real F-keys, never both. With `fnState = false` (the default, and the setting used here) the row sends **media keys**, so brightness and volume are one bare press — and `fn` is what produces the real F4 keycode. So the screenshot hotkey, bound to F4 with no modifiers, fires on **`fn+F4`**. macOS doesn't treat `fn` as a modifier when matching the hotkey, so no modifier flags are needed in the binding.

Setting `fnState = true` would invert this: bare `F4` would take the screenshot, but brightness/volume would then need `fn` held — globally, for every app. That trade wasn't worth it; media keys get pressed far more often than the screenshot key. If you'd rather have bare `F4`, flip the value and the hotkey binding below still works unchanged.

The hotkey's `parameters` array is `[asciiCode, keyCode, modifierFlags]` — `65535` means "no ASCII character" (correct for function keys), `118` is F4's virtual keycode, `0` is no modifiers.

### Replication (fresh macOS)

```bash
mkdir -p ~/screenshots
defaults write com.apple.screencapture location "$HOME/screenshots"
defaults write com.apple.screencapture type png

# Keep the top row as media keys (brightness/volume on a bare press).
# `fn` then yields the real F4 keycode, so the hotkey below fires on fn+F4.
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool false

# Rebind "Save picture of screen as a file" (hotkey 28) to F4
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 28 '
<dict>
  <key>enabled</key><true/>
  <key>value</key><dict>
    <key>parameters</key>
    <array>
      <integer>65535</integer>
      <integer>118</integer>
      <integer>0</integer>
    </array>
    <key>type</key><string>standard</string>
  </dict>
</dict>'

killall SystemUIServer
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
```

**Log out and back in** for the new hotkey to take effect — `activateSettings -u` reloads most prefs, but the symbolic-hotkey table is only re-read by the WindowServer at login.

The same applies to `fnState`: the WindowServer caches it at login, so the live top-row behaviour can disagree with what `defaults read` reports until you log out. If the keyboard is behaving the opposite of the stored value, that drift is why — log out, or toggle it once in *System Settings → Keyboard → Keyboard Shortcuts → Function Keys*, which writes through the path the WindowServer actually listens to.

To revert: set hotkey 28's `parameters` back to `[51, 20, 1179648]` (`⌘⇧3`), or just re-enable it in *System Settings → Keyboard → Keyboard Shortcuts → Screenshots*.

## Keeping the Mac awake — `keepawake`

`scripts/keepawake` (lives at `~/.local/bin/keepawake` on the machine) keeps the display from sleeping during long unattended runs — training jobs, downloads, remote sessions. It's a thin wrapper over macOS's built-in **`caffeinate`**, so there's no app to install and nothing running in the menu bar.

| Command | Effect |
|---|---|
| `keepawake` | toggle on/off |
| `keepawake on` | start it (`caffeinate -d`, backgrounded via `nohup`) |
| `keepawake off` | stop it, restore normal sleep |
| `keepawake status` | report both the caffeinate state and lid mode |
| `keepawake lid` | *also* keep running with the lid **closed** (`sudo pmset -a disablesleep 1`) |
| `keepawake lid-off` | restore normal lid-close sleep |

**Two independent levels, and the difference matters.** The default (`on`) uses `caffeinate -d`, which blocks only *idle* display sleep — pressing the power button, choosing Apple menu → Sleep, or closing the lid still sleeps the Mac immediately, exactly as normal. It's safe to leave on and it dies with a reboot.

`lid` is the sharper tool: `pmset -a disablesleep 1` disables sleep **entirely**, including the Apple-menu and lid-close paths, and it **persists across reboots**. That's the one to be careful with — a Mac in a bag with the lid shut and lid mode on will stay running and cook. `keepawake off` deliberately does *not* clear it (they're separate mechanisms); instead it prints a reminder if lid mode is still active, and `status` always shows both. Run `keepawake lid-off` when you're done.

State is tracked with a pidfile at `${TMPDIR:-/tmp}/keepawake.pid`, so `status`/`toggle` survive across shells but reset on reboot — which is the intent, since the underlying `caffeinate` process doesn't survive either.

### Replication (fresh macOS)

Nothing to install — `caffeinate` and `pmset` are stock macOS. Just drop the script in and alias it:

```bash
mkdir -p ~/.local/bin
cp scripts/keepawake ~/.local/bin/keepawake
chmod +x ~/.local/bin/keepawake

# ~/.local/bin is already on PATH via .zshrc; the alias is there for discoverability
echo "alias keepawake='~/.local/bin/keepawake'" >> ~/.zshrc && source ~/.zshrc
```

`keepawake lid` prompts for `sudo` (it's the only subcommand that needs it).

## Keeping the Mac responsive — `heat-guard`

This Mac (M5 Pro, 24 GB) runs about 25 coding-agent sessions at once. **heat-guard**
(`~/personal-ws/heat-guard`, a local git repo with no dependencies, Node 20+) is a LaunchAgent that
runs once a minute and sheds runaway *development* load. That means tests, dev servers and
Playwright browsers. It never touches agents (`claude` / `codex`), anything above them, or ordinary
apps.

| Rule | What it does |
|---|---|
| K-mem | Kill a test/dev process tree whose footprint reaches all of RAM (re-checked every 10 s) |
| K-pressure | **high** (swap ≥ 0.6 × RAM): kill orphaned Playwright/Puppeteer browsers ≥ 10 min old. **critical** (kernel pressure ≥ warn, or ≤ 12% free): also kill the largest test/dev tree every 10 s until it clears, and notify |
| K-orphan / K-shell | Kill orphaned tests burning a core for an hour; kill ownerless agent shells after 6 h |
| Throttle / N-hot | Background-priority hot jobs over an 8-core budget; notify on long-hot jobs |
| Gate | Claude Code `PreToolUse` hook: block whole-suite test runs above 10 hot cores, or while memory is high/critical |

```bash
cd ~/personal-ws/heat-guard
node bin/heat-guard status          # memory stage, hot cores, what it would act on
node bin/heat-guard run --dry-run   # read-only full pass
node bin/heat-guard install         # write + load ~/Library/LaunchAgents/com.aris.heat-guard.plist
tail ~/Library/Logs/heat-guard.log  # kills, notifications, memory-thrash/pressure events
```

Turn killing off with `{"kill": false}` in `~/.config/heat-guard/config.json`. Kills then become
"would kill" notifications. The memory rules exist because of the
[2026-11-15 freeze](docs/incidents/2026-11-15-mac-memory-exhaustion-freeze.md). heat-guard can
only shed about 5 GB of dev load, though. The structural load is open sessions (about 0.7 GB each
with their MCP servers) plus iTerm, so a Mac with high swap means closing idle sessions.

## External-monitor brightness (macOS) — MonitorControl

The brightness keys on the top row (`F1`/`F2` — media keys on a bare press, since `fnState = false`, see the Screenshots section) only ever reach the **built-in** display. External monitors take brightness/contrast/volume over **DDC/CI** (the VESA control channel that rides on the display cable's I2C lines), and macOS has no UI or API for it. [**MonitorControl**](https://github.com/MonitorControl/MonitorControl) (open source, menu-bar app) speaks DDC/CI, so the same brightness keys — and the volume keys, for monitors with speakers — drive whichever display the cursor is on, plus per-display sliders under the menu-bar icon. This laptop runs two external 1080p displays, so without it every brightness change on them was a trip through the monitor's own OSD buttons. Displays that don't answer DDC/CI get a **software** fallback: a gamma-table overlay that darkens the image without touching the backlight.

**Current setup on this machine.** `/Applications/MonitorControl.app` 4.4.0, bundle id **`app.monitorcontrol.MonitorControl`** (not the older `me.guillaumeb.MonitorControl` most web guides quote; `defaults read` on that domain reports "does not exist" here). It was installed by hand from the `.dmg`, **not** via Homebrew, and every app-level setting is at its default: menu-bar icon shown, brightness and volume keys intercepted. The plist only holds per-display state; `isTouched16(<display>@<n>) = 1` for a display means brightness has actually been written to it over DDC, which is the useful thing to check.

**Accessibility permission is the silent one.** Intercepting the brightness/volume keys needs *System Settings → Privacy & Security → Accessibility*. Without it the app runs, the menu-bar sliders work, and the keys keep changing only the built-in display — nothing looks broken. It's a TCC grant, so it can't be scripted; one click, once per machine.

**DDC/CI has to survive the cable path.** Some monitors ship with DDC/CI off in their own OSD menu, and some paths never carry it: USB-C/Thunderbolt hubs and especially **DisplayLink** docks are the usual culprit (the DisplayLink driver doesn't expose DDC). Symptom: the display appears in MonitorControl but only the software-dim slider moves — the image darkens, the backlight doesn't. Try a direct HDMI/DisplayPort cable before blaming the monitor.

**The DDC knobs are hidden.** Per-display DDC on/off, the software-dimming fallback, VCP ranges and polling live behind *Settings → Advanced → Show advanced settings*; the default view shows none of them.

**Bringing it under Homebrew.** The cask is `monitorcontrol` (4.4.0, `auto_updates`). Because the copy here was installed by hand, `brew install --cask monitorcontrol --adopt` takes over the existing `/Applications/MonitorControl.app` without reinstalling; a fresh machine just uses the plain install. `auto_updates` means `brew upgrade` leaves it alone and the in-app Sparkle updater (on by default, as above) does the updating.

### Replication (fresh macOS)

```bash
brew install --cask monitorcontrol   # machine with a hand-installed copy: add --adopt

# First launch puts the icon in the menu bar and asks for Accessibility
open -a MonitorControl

# Grant it (can't be scripted): Privacy & Security -> Accessibility -> enable MonitorControl
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

# Start at login: menu-bar icon -> Settings -> General -> "Start at login"
# (or System Settings -> General -> Login Items & Extensions)

# Sanity check: cursor on an external display, press the brightness key, watch that
# monitor's own OSD move. Then confirm DDC writes landed:
pgrep -x MonitorControl && defaults read app.monitorcontrol.MonitorControl | grep -E 'isTouched16|SwBrightness'
```

`isTouched16(<display>@<n>) = 1` for a display is the proof DDC is actually reaching it. If only its `SwBrightness(...)` value moves when you press the keys, DDC isn't getting through — see the dock trap above.

## Window tiling (Linux / GNOME) — Rectangle-style shortcuts

On the Linux box (Ubuntu, **GNOME Shell on Wayland**), window snapping is set up to feel like macOS **Rectangle**, driven by the pre-installed **Tiling Assistant** extension (`tiling-assistant@ubuntu.com`).

**Modifier choice:** the trigger is `Ctrl + Super`. On a Logitech multi-OS keyboard, `Super` is the key labelled **`start / ⌘`** (the Command key in Mac mode). The key labelled `alt / opt` is plain **Alt** on Linux — Linux has no separate "Option" modifier. `Ctrl+Alt+Arrow` was avoided because it collides with GNOME's default workspace switching.

| Action | Shortcut |
|---|---|
| Left / Right / Top / Bottom half | `Ctrl + Super + ← / → / ↑ / ↓` |
| Thirds (½ → ⅔ → ⅓) | press the same arrow repeatedly |
| Maximize | `Ctrl + Super + Return` |
| Quarters (TL / TR / BL / BR) | `Ctrl + Super + U / I / J / K` |
| Restore / un-tile | `Ctrl + Super + Backspace` |

The "tiling popup" (snap-assist that asks you to fill the other half with another app) is **disabled**, so snapping one half leaves the rest of the screen untouched. Workspace switching was moved off the arrow keys onto `Super + Alt + Arrows` (plus the stock `Super + PageUp/PageDown`) to free up the tiling chords.

### Replication (fresh GNOME / Ubuntu)

Tiling Assistant ships with Ubuntu; ensure it's enabled, then apply the gsettings:

```bash
gnome-extensions enable tiling-assistant@ubuntu.com

TA=org.gnome.shell.extensions.tiling-assistant
gsettings set $TA tile-left-half           "['<Control><Super>Left']"
gsettings set $TA tile-right-half          "['<Control><Super>Right']"
gsettings set $TA tile-top-half            "['<Control><Super>Up']"
gsettings set $TA tile-bottom-half         "['<Control><Super>Down']"
gsettings set $TA tile-maximize            "['<Control><Super>Return']"
gsettings set $TA tile-topleft-quarter     "['<Control><Super>u']"
gsettings set $TA tile-topright-quarter    "['<Control><Super>i']"
gsettings set $TA tile-bottomleft-quarter  "['<Control><Super>j']"
gsettings set $TA tile-bottomright-quarter "['<Control><Super>k']"
gsettings set $TA restore-window           "['<Control><Super>BackSpace']"
gsettings set $TA enable-tiling-popup false   # no "fill the other half" prompt

# Move workspace switching off Ctrl+Alt+Arrows so the tiling chords are free
WM=org.gnome.desktop.wm.keybindings
gsettings set $WM switch-to-workspace-left  "['<Super>Page_Up', '<Super>KP_Prior', '<Super><Alt>Left']"
gsettings set $WM switch-to-workspace-right "['<Super>Page_Down', '<Super>KP_Next', '<Super><Alt>Right']"
gsettings set $WM switch-to-workspace-up    "['<Super><Alt>Up']"
gsettings set $WM switch-to-workspace-down  "['<Super><Alt>Down']"

# Force the extension to re-grab the keys
gnome-extensions disable tiling-assistant@ubuntu.com && gnome-extensions enable tiling-assistant@ubuntu.com
```

To restore the snap-assist popup later: `gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup true`.

## Claude Code notifications — sound + tab colour

Claude Code runs long turns, so it's easy to wander off and miss the moment it needs an answer. Two ambient cues fix that, both driven by **hooks** in `~/.claude/settings.json` (hooks are the only mechanism here — Claude executes nothing automatic from memory or preferences; the harness runs these commands on lifecycle events).

| Event | Meaning | Sound | Tab |
|---|---|---|---|
| `Notification` | Claude wants input — a permission prompt or a question | `Submarine` (low sonar bloop) | solid **light pink** |
| `Stop` | Claude finished its turn | `Blow` (soft breathy chime) | solid **matcha green** |
| `UserPromptSubmit` | you sent a prompt; work is underway | — | reset to default |
| `SessionEnd` | session over | — | reset to default |

Sounds are stock macOS (`/System/Library/Sounds/*.aiff`, played with `afplay` — no dependency). The other 12 to choose from: Basso, Bottle, Frog, Funk, Glass, Hero, Morse, Ping, Pop, Purr, Sosumi, Tink.

All four hooks are marked `"async": true` so they never add latency to a turn.

### The tab colour script — `scripts/claude-tab-color.sh`

Lives at `~/.claude/tab-color.sh` on the machine. Takes one argument: `flash`, `done`, or `clear`.

**iTerm2 only.** Tab colour is set with a proprietary iTerm2 escape sequence (`OSC 6 ; 1 ; bg ; <channel> ; brightness ; <0-255>`), reset with `OSC 6 ; 1 ; bg ; * ; default`. Terminal.app has no equivalent.

Two implementation details that are easy to get wrong:

- **Hook stdout never reaches the terminal.** Claude Code captures it, so a `printf '\033]6;...'` to stdout does nothing. The script walks up the process tree (`ps -o ppid=`) until it finds an ancestor with a real controlling tty, then writes the escape sequence straight to that device (e.g. `/dev/ttys006`).
- **Don't animate the tab colour.** An earlier version of this script pulsed pink with a smoothstep fade, forked as a background loop. iTerm2 treats every OSC 6 sequence as a session-profile mutation, so even a modest frame rate pegs its main thread. The colours are now set statically, once per event. `stop_flasher` survives only to kill a stray loop left over from that version — it reads `/tmp/claude-tabcolor-<tty>.pid` and can be dropped once no old sessions remain.

Pink now means one thing: **Claude is blocked on you.** It's set from the `Notification` hook only, which fires on permission prompts and questions — not on ordinary turn completion, which gets matcha green instead. Tune `PINK_*` / `MATCHA_*` at the top of the script for colour.

### Replication (fresh macOS + iTerm2)

```bash
# 1. The tab-colour script
cp scripts/claude-tab-color.sh ~/.claude/tab-color.sh
chmod +x ~/.claude/tab-color.sh

# 2. Merge scripts/claude-settings-hooks.json into ~/.claude/settings.json.
#    NOTE: jq's `*` replaces same-named arrays wholesale — it does NOT append.
#    Safe only if you have no Notification/Stop/UserPromptSubmit/SessionEnd hooks
#    already; otherwise hand-merge, or you'll silently drop the existing ones.
jq -s '.[0] * .[1]' ~/.claude/settings.json scripts/claude-settings-hooks.json \
  > /tmp/cc.json && mv /tmp/cc.json ~/.claude/settings.json

# 3. Sanity-check the wiring, then preview the cues
jq -e '.hooks | keys' ~/.claude/settings.json
~/.claude/tab-color.sh flash   # tab goes light pink
~/.claude/tab-color.sh done    # tab goes matcha green
~/.claude/tab-color.sh clear   # tab resets
```

Claude Code only watches directories that already had a settings file when the session started, so **new hooks don't fire until the config reloads** — open `/hooks` once, or restart Claude Code.
