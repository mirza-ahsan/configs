-- ~/.config/nvim/lua/plugins/lsp.lua
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        -- =====================================================================
        -- DIAGNOSTICS CONFIGURATION (Modern Neovim API)
        -- =====================================================================

        -- Configure how errors display and set the custom icons natively
        vim.diagnostic.config({
            virtual_text = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = " ",
                    [vim.diagnostic.severity.WARN] = " ",
                    [vim.diagnostic.severity.INFO] = " ",
                    [vim.diagnostic.severity.HINT] = "󰠠 ",
                },
            },
            update_in_insert = false,
            underline = true,
            severity_sort = true,
            float = {
                border = "rounded",
                source = "always",
            },
        })

        -- The magic keybinds to read and jump between errors
        vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show full error message" })
        vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end,
            { desc = "Go to previous error" })
        vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end,
            { desc = "Go to next error" })

        -- =====================================================================
        -- LSP SERVER SETUP
        -- =====================================================================

        require("mason").setup()

        require("mason-lspconfig").setup({
            ensure_installed = {
                "clangd",        -- C/C++
                "pylsp",         -- Python
                "rust_analyzer", -- Rust
                "ts_ls",         -- JS/TS
                "gopls",         -- Go
                "lua_ls",        -- Lua Language Server
            },
            automatic_installation = true,
        })

        -- Get the advanced capabilities from blink.cmp
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        -- Neovim 0.11+ Native LSP Configuration
        local servers = { "rust_analyzer", "ts_ls", "gopls", "lua_ls" }
        for _, server in ipairs(servers) do
            vim.lsp.config(server, {
                capabilities = capabilities,
            })
            vim.lsp.enable(server)
        end

        -- pylsp: set pycodestyle line length to 110
        vim.lsp.config("pylsp", {
            capabilities = capabilities,
            settings = {
                pylsp = {
                    plugins = {
                        pycodestyle = {
                            maxLineLength = 110,
                        },
                    },
                },
            },
        })
        vim.lsp.enable("pylsp")

        -- clangd: disable auto-inserting #include on completion
        vim.lsp.config("clangd", {
            capabilities = capabilities,
            cmd = { "clangd", "--header-insertion=never" },
        })
        vim.lsp.enable("clangd")

        -- Dart special case (uses your system's Dart SDK)
        vim.lsp.config("dartls", {
            capabilities = capabilities,
        })
        vim.lsp.enable("dartls")

        -- =====================================================================
        -- LSP ATTACH (Keymaps & Overrides)
        -- =====================================================================

        -- Essential LSP Keymaps (Only load when an LSP attaches to a buffer)
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Disable LSP semantic highlights so Treesitter colors pop
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if client then
                    client.server_capabilities.semanticTokensProvider = nil
                end

                local opts = { buffer = ev.buf }
                vim.keymap.set(
                    "n",
                    "K",
                    vim.lsp.buf.hover,
                    vim.tbl_extend("force", opts, { desc = "Hover Documentation" })
                )
                vim.keymap.set(
                    "n",
                    "gd",
                    vim.lsp.buf.definition,
                    vim.tbl_extend("force", opts, { desc = "Go to Definition" })
                )
                vim.keymap.set(
                    "n",
                    "<leader>ca",
                    vim.lsp.buf.code_action,
                    vim.tbl_extend("force", opts, { desc = "Code Action" })
                )
                vim.keymap.set(
                    "n",
                    "<leader>rn",
                    vim.lsp.buf.rename,
                    vim.tbl_extend("force", opts, { desc = "Rename Symbol" })
                )
                vim.keymap.set(
                    "n",
                    "gr",
                    require("telescope.builtin").lsp_references,
                    vim.tbl_extend("force", opts, { desc = "Find References" })
                )
            end,
        })
    end,
}
