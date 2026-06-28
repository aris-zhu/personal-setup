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

**Aliases:**
- `vim=nvim`
- `vimrc=nvim ~/.config/nvim/init.lua`
- `zshrc='nvim ~/.zshrc && source ~/.zshrc'`
- `szsh='source ~/.zshrc'`
- project shortcuts: `prompt`, `server`, `hyde`
- `nb=jupyter notebook`
- `cab='conda activate base'`

**PATH/env:** homebrew python/ruby, `~/.local/bin`, `~/.cargo/bin`, conda init block, `eval "$(~/.local/bin/mise activate)"`, `OPENSSL_ROOT_DIR`, Docker bin, `postgresql@16` bin.

## Replication steps (fresh macOS)

```bash
# 1. Core tools
brew install neovim ripgrep fd git
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2. Drop in configs (copy these files from this machine)
#   ~/.config/nvim/init.lua
#   ~/.config/nvim/lazy-lock.json   <- keeps exact plugin versions
#   ~/.zshrc   (set ZSH_THEME="gallifrey")
#   ~/.zshenv

# 3. First nvim launch bootstraps lazy.nvim and installs all plugins.
#    To get byte-identical plugin versions:
nvim --headless "+Lazy! restore" +qa     # restores commits from lazy-lock.json
```

Install a Nerd Font for the file-tree icons. `mise`, `conda`, Docker, and `postgresql@16` are referenced in `.zshrc` but are optional unless you need those toolchains.

The whole nvim setup is just two files (`init.lua` + `lazy-lock.json`, ~7KB total) — copy them plus `ripgrep`/`fd` and you've reproduced the editor exactly.
