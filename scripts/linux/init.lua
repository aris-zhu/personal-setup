-- init.lua — single self-contained Neovim config.
-- Structure: leader -> options -> keymaps -> plugin bootstrap -> plugins.

--------------------------------------------------------------------------------
-- Leader
--------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- nvim-tree replaces netrw; disable it before any plugin loads.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------
local opt = vim.opt

opt.number = true
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.ignorecase = true
opt.smartcase = true

opt.wildmenu = true
opt.wildmode = "full"

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Escape to normal mode" })

map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "gh", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>g", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })

map("n", "<C-n>", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })

--------------------------------------------------------------------------------
-- Drop Neovim's built-in gr-prefixed LSP defaults.
--
-- Neovim 0.11+ maps grn/gra/grr/gri/grt/grx. Leaving them in place makes a bare
-- `gr` ambiguous -- Neovim waits out `timeoutlen` (~1s) to see whether another
-- `r` is coming before firing. Deleting them makes `gr` fire instantly; the two
-- genuinely useful ones are re-homed on <leader>rn / <leader>ca below.
--
-- If a future gr-prefixed default lands upstream and `gr` starts feeling laggy
-- again, add it to this list.
--------------------------------------------------------------------------------
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, "n", lhs)
end

--------------------------------------------------------------------------------
-- LSP keymaps -- buffer-local, so `gd` keeps its built-in "local declaration"
-- meaning in files with no language server attached. Navigation goes through
-- Telescope pickers: a single result jumps straight there, multiple results
-- open a fuzzy-searchable list.
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
    callback = function(args)
        local bufopts = function(desc)
            return { buffer = args.buf, desc = desc }
        end

        map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", bufopts("Go to definition"))
        map("n", "gr", "<cmd>Telescope lsp_references<cr>", bufopts("List references"))
        map("n", "gy", "<cmd>Telescope lsp_type_definitions<cr>", bufopts("Go to type definition"))
        map("n", "<leader>gi", "<cmd>Telescope lsp_implementations<cr>", bufopts("List implementations"))
        map("n", "<leader>rn", vim.lsp.buf.rename, bufopts("Rename symbol"))
        map("n", "<leader>ca", vim.lsp.buf.code_action, bufopts("Code action"))
        -- K (hover) and [d / ]d (diagnostics) are Neovim built-in defaults.
    end,
})

--------------------------------------------------------------------------------
-- Auto-save the zsh dotfiles while editing them, so `zshrc`'s trailing
-- `source ~/.zshrc` always picks up the latest text.
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = vim.api.nvim_create_augroup("AutoSaveZshDotfiles", { clear = true }),
    pattern = { "*/.zshrc", "*/.zprofile", "*/.zshenv" },
    callback = function()
        if vim.bo.modifiable and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
            vim.cmd("silent! write")
        end
    end,
})

--------------------------------------------------------------------------------
-- Plugin bootstrap -- lazy.nvim installs itself on first launch.
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- Plugins
--------------------------------------------------------------------------------
require("lazy").setup({
    -- Fuzzy find & grep. live_grep requires ripgrep on PATH; find_files uses fd.
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("telescope").setup({})
        end,
    },

    -- File tree.
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                view = { width = 35 },
                renderer = { group_empty = true },
            })
        end,
    },

    -- gcc / gc commenting.
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },

    -- Completion: supertab-style <Tab>/<S-Tab> cycling, <CR> to confirm.
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },

    -- LSP client configs. nvim-lspconfig ships the server definitions (cmd,
    -- filetypes, root markers); Neovim 0.11+ starts them via vim.lsp.enable.
    {
        "neovim/nvim-lspconfig",
        dependencies = { "hrsh7th/cmp-nvim-lsp" },
        config = function()
            -- Advertise nvim-cmp's completion capabilities to every server, which
            -- is what routes LSP completions into the existing <Tab> menu.
            vim.lsp.config("*", {
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
            })

            -- lua_ls: LuaJIT, `vim` is injected by the editor rather than
            -- declared, and point it at the Neovim runtime so `gd` works on
            -- Neovim's own API functions.
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            })

            -- Two servers, because that's what this machine actually writes:
            -- TypeScript projects and this init.lua. Adding another is one entry
            -- here plus installing its binary.
            vim.lsp.enable({ "ts_ls", "lua_ls" })
        end,
    },
})
