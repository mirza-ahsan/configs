-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

-- LazyVim sets <leader> to Space; use Space for <localleader> too
vim.g.maplocalleader = " "

-- Format on save (Zed: format_on_save = "on")
vim.g.autoformat = true

local opt = vim.opt

-- UI and Performance
opt.guicursor = "" -- Block cursor everywhere
opt.scrolloff = 8 -- Zed: vertical_scroll_margin = 8
opt.updatetime = 50
opt.signcolumn = "yes"
opt.cursorline = false -- Zed: current_line_highlight = "none"

-- Line Numbers (relative in normal mode, absolute in insert; see autocmds)
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search
opt.hlsearch = false
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Files, Backup, and Undo
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undodir"
opt.fixendofline = false -- Zed: ensure_final_newline_on_save = false

-- System clipboard only through <leader>y (Zed: use_system_clipboard = "never")
opt.clipboard = ""

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Netrw (<leader>pv)
vim.g.netrw_keepdir = 0
vim.g.netrw_winsize = 25
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_browse_split = 0
