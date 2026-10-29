-- Personal setup on top of Omarchy's LazyVim, tuned to behave like the Zed config.
-- Colors stay with Omarchy's theme (plugins/theme.lua); nothing here sets a colorscheme.
return {
  -- LSP: same servers as Zed, system binaries where they're installed
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false }, -- no inline "format:" / type hints
      codelens = { enabled = true }, -- Zed: code_lens = "on"
      diagnostics = {
        virtual_text = true,
        update_in_insert = false,
        float = { border = "rounded", source = true },
      },
      servers = {
        ["*"] = {
          keys = {
            { "gr", function() Snacks.picker.lsp_references() end, desc = "Find References", nowait = true },
            { "<leader>rn", vim.lsp.buf.rename, desc = "Rename Symbol", has = "rename" },
          },
        },
        pyrefly = {
          mason = false,
          init_options = {
            pyrefly = {
              typeCheckingMode = "default",
              analysis = {
                autoImportCompletions = false,
                completeFunctionParens = true,
                showHoverGoToLinks = true,
                inlayHints = {
                  variableTypes = true,
                  functionReturnTypes = true,
                  callArgumentNames = "off",
                  pytestParameters = false,
                },
              },
            },
          },
        },
        -- pyrefly already reports these; keeping them in ruff too shows every one twice.
        ruff = {
          mason = false,
          init_options = {
            settings = { lint = { ignore = { "F401", "F821", "F841" } } },
          },
        },
        clangd = { mason = false, cmd = { "clangd", "--header-insertion=never" } },
        gopls = { mason = false },
        -- rustup's proxy (Arch keeps it out of PATH); follows the active toolchain
        rust_analyzer = { mason = false, cmd = { "/usr/lib/rustup/bin/rust-analyzer" } },
        ts_ls = {},
      },
    },
  },

  -- Formatters (Zed: ruff for Python, clangd/gopls style for C/Go, prettier for JS/TS)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        go = { "gofmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        lua = { "stylua" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "prettier" })
    end,
  },

  -- Completion: Tab accepts
  {
    "saghen/blink.cmp",
    opts = {
      keymap = { preset = "super-tab" },
      signature = { enabled = true },
    },
  },

  -- Command palette UI only; messages/notifications stay with LazyVim's notifier
  {
    "folke/noice.nvim",
    opts = {
      presets = { command_palette = true },
      messages = { enabled = false },
      notify = { enabled = false },
      popupmenu = { enabled = false },
      lsp = { progress = { enabled = false } },
    },
  },

  -- File browsing is netrw only (<leader>pv, and <C-S-e> for a right-side panel)
  -- Free up Shift-S so it keeps its built-in meaning (clear the line, keep the indent).
  { "folke/flash.nvim", keys = { { "S", mode = { "n", "x", "o" }, false } } },

  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- Zed: no tab bar
  { "akinsho/bufferline.nvim", enabled = false },

  -- Zed: git gutter hidden (hunk navigation/actions still work)
  { "lewis6991/gitsigns.nvim", opts = { signcolumn = false } },

  -- Zed: no selection/reference highlight; personal maps replace these picker keys
  {
    "folke/snacks.nvim",
    opts = { words = { enabled = false } },
    keys = {
      { "<leader>fb", false },
      { "<leader>fg", false },
      { "<leader>sh", false },
    },
  },

  -- Extra Treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bash", "c", "cpp", "css", "dart", "go", "html", "javascript", "json", "lua", "make",
        "markdown", "markdown_inline", "python", "rust", "tsx", "typescript", "vim", "vimdoc", "yaml",
      })
    end,
  },

  -- Jupyter (Molten) with images rendered through the Kitty graphics protocol (Ghostty)
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_width_window_percentage = 100,
      max_height_window_percentage = 100,
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      editor_only_render_when_focused = false,
      tmux_show_only_in_active_window = false,
    },
  },
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    dependencies = { "3rd/image.nvim" },
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = false
      vim.g.molten_virt_lines_off_by_1 = false
    end,
    config = function()
      local map = vim.keymap.set
      map("n", "<localleader>mi", ":MoltenInit AI<CR>", { desc = "Initialize Molten for AI Env", silent = true })
      map("n", "<localleader>e", ":MoltenEvaluateOperator<CR>", { desc = "Run Operator", silent = true })
      map("n", "<localleader>rl", ":MoltenEvaluateLine<CR>", { desc = "Evaluate Line", silent = true })
      map("n", "<localleader>rc", ":MoltenReevaluateCell<CR>", { desc = "Re-evaluate Cell", silent = true })
      map("v", "<localleader>r", ":<C-u>MoltenEvaluateVisual<CR>gv", { desc = "Evaluate Visual Selection", silent = true })
      map("n", "<localleader>os", ":noautocmd MoltenEnterOutput<CR>", { desc = "Show Output", silent = true })
      map("n", "<localleader>oh", ":MoltenHideOutput<CR>", { desc = "Hide Output", silent = true })
      map("n", "<localleader>md", ":MoltenDelete<CR>", { desc = "Delete Molten Cell", silent = true })
    end,
  },
}
