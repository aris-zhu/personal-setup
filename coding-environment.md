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
- A **Nerd Font** in the terminal for nvim-web-devicons icons to render

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

Install a Nerd Font for the file-tree icons. `mise`, `conda`, Docker, and `postgresql@16` are referenced in `.zshrc` but are optional unless you need those toolchains.

The whole nvim setup is still just two files (`init.lua` + `lazy-lock.json`, ~9KB total) — copy them plus `ripgrep`/`fd` and the language-server binaries from step 1a, and you've reproduced the editor exactly.

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
