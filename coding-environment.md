# Coding Environment

A replicable description of the current Neovim + zsh setup, including plugins, keybindings, and external dependencies.

## Overview

| Layer | Tool | Notes |
|---|---|---|
| Editor | **Neovim 0.12.3** (LuaJIT 2.1) | config at `~/.config/nvim/` |
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

### Plugins

5 user plugins + dependencies, all commit-pinned in `lazy-lock.json`:

- `telescope.nvim` (branch `0.1.x`) + `plenary.nvim` — fuzzy find & grep
- `nvim-tree.lua` + `nvim-web-devicons` — file tree, 35-col width, `group_empty=true`
- `Comment.nvim` — `gcc`/`gc` commenting
- `nvim-cmp` + `cmp-buffer`, `cmp-path`, `LuaSnip`, `cmp_luasnip` — completion

### Custom autocmd

Auto-saves `.zshrc` / `.zprofile` / `.zshenv` on `InsertLeave`/`TextChanged` while editing them.

### External CLI dependencies

Telescope needs these (all currently installed):

- `ripgrep` 15.1.0 (`rg`, **required** for live_grep)
- `fd` 10.4.2 (find_files)
- `git` (used by lazy.nvim to clone plugins)
- A **Nerd Font** in the terminal for nvim-web-devicons icons to render

## Shell — `~/.zshrc`

- oh-my-zsh, `ZSH_THEME="gallifrey"`, no `plugins=(...)` array (stock omz only)
- `.zshenv` just sources `~/.cargo/env`

**Git branch in prompt:** the `gallifrey` theme shows the current branch on the right-hand side of the prompt (rendered asynchronously, so it appears a beat after the prompt draws). `.zshrc` also contains a self-contained `vcs_info` fallback that draws `(branch)` inline — it's guarded by `if ! typeset -f git_prompt_info` so it **only activates when oh-my-zsh isn't loaded**; once omz/gallifrey is present, the theme drives the branch and the fallback disables itself.

**Aliases:**
- `vim=nvim`
- `vimrc=nvim ~/.config/nvim/init.lua` — edit the Neovim config
- `zshrc='nvim ~/.zshrc && source ~/.zshrc'` — edit `~/.zshrc`, then auto-reload it into the current shell on quit (a shell can't reload its own parent, so the `source` runs after nvim exits)
- `szsh='source ~/.zshrc'` — just reload `~/.zshrc` into the current shell without editing (handy after changing it elsewhere)
- project shortcuts: `prompt`, `server`, `hyde`
- `nb=jupyter notebook`
- `cab='conda activate base'`

**PATH/env:** homebrew python/ruby, `~/.local/bin`, `~/.cargo/bin`, conda init block, `eval "$(~/.local/bin/mise activate)"`, `OPENSSL_ROOT_DIR`, Docker bin, `postgresql@16` bin.

## Replication steps (fresh macOS)

```bash
# 1. Core tools  (macOS: brew | Ubuntu/Debian: sudo apt install neovim ripgrep fd-find git zsh)
brew install neovim ripgrep fd git

# 1b. oh-my-zsh — install WITHOUT overwriting the hand-maintained ~/.zshrc.
#     --keep-zshrc preserves it; --unattended skips the chsh prompt.
RUNZSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended --keep-zshrc

# 2. Drop in configs (copy these files from this machine)
#   ~/.config/nvim/init.lua
#   ~/.config/nvim/lazy-lock.json   <- keeps exact plugin versions
#   ~/.zshrc   (ZSH_THEME="gallifrey"; already sources omz + the vcs_info branch fallback)
#   ~/.zshenv

# 3. First nvim launch bootstraps lazy.nvim and installs all plugins.
#    To get byte-identical plugin versions:
nvim --headless "+Lazy! restore" +qa     # restores commits from lazy-lock.json
```

Install a Nerd Font for the file-tree icons. `mise`, `conda`, Docker, and `postgresql@16` are referenced in `.zshrc` but are optional unless you need those toolchains.

The whole nvim setup is just two files (`init.lua` + `lazy-lock.json`, ~7KB total) — copy them plus `ripgrep`/`fd` and you've reproduced the editor exactly.

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
