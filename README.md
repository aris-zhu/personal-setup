# personal-setup

Notes and scripts for reproducing my day-to-day dev environment: Neovim, zsh, and a handful of
macOS/GNOME quality-of-life tweaks.

This repo is **documentation-first**. The configs themselves live where the tools expect them
(`~/.config/nvim/init.lua`, `~/.zshrc`); what's tracked here is the description of that setup plus
the standalone scripts it depends on. The goal is that a fresh machine can be brought back to this
state by reading one file and running the commands in it.

## What's here

| Path | What it is |
|---|---|
| [`coding-environment.md`](coding-environment.md) | The main document — editor, shell, keybindings, dependencies, and step-by-step replication |
| `scripts/keepawake` | Toggles display-sleep prevention (wraps `caffeinate`) |
| `scripts/claude-tab-color.sh` | Colours the iTerm2 tab on Claude Code events |
| `scripts/claude-settings-hooks.json` | The Claude Code hook config that drives the script above |

## Start here

New machine? Go straight to
[Replication steps](coding-environment.md#replication-steps-fresh-macos) — it's a copy-pasteable
block covering Homebrew packages, oh-my-zsh (installed without clobbering the hand-maintained
`.zshrc`), language servers, and restoring exact plugin versions from the lockfile.

Otherwise `coding-environment.md` is organised as:

- **[Overview](coding-environment.md#overview)** — the tools and versions at a glance
- **[Neovim](coding-environment.md#neovim--confignviminitlua)** — options, keymaps, LSP, plugins,
  external dependencies
- **[Shell](coding-environment.md#shell--zshrc)** — oh-my-zsh, prompt, aliases, PATH
- **Extras** — [screenshots on `fn+F4`](coding-environment.md#screenshots-macos--fnf4),
  [`keepawake`](coding-environment.md#keeping-the-mac-awake--keepawake),
  [GNOME window tiling](coding-environment.md#window-tiling-linux--gnome--rectangle-style-shortcuts),
  [Claude Code notification cues](coding-environment.md#claude-code-notifications--sound--tab-colour)

## The editor in one paragraph

Neovim 0.12 with a single self-contained `init.lua` and `lazy.nvim` as the plugin manager, with every
plugin commit-pinned in `lazy-lock.json`. Telescope for finding files and grepping, nvim-tree for the
file tree, nvim-cmp for completion, and LSP (`ts_ls` + `lua_ls`) behind `gd` / `gr` for jumping to a
definition and listing every use of a symbol. Two files, ~9KB, no framework.

## Conventions

- **Pin things.** Plugins are pinned in `lazy-lock.json`; `Lazy! restore` reproduces them exactly.
  Prefer `Lazy! restore` over `Lazy! sync` unless you actually intend to upgrade — `sync` updates
  every plugin and rewrites the lockfile.
- **Write down the *why*, not just the *what*.** The non-obvious traps (the `gr`-prefix keymap
  conflict, the TypeScript 7.x language-server breakage, `--keep-zshrc`) are the parts of this repo
  worth having.
- **Keep it copy-pasteable.** Commands in the docs should run as written.
