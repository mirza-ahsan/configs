-- ~/.config/nvim/lua/plugins/conform.lua
return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" }, -- This triggers the format RIGHT before the file saves
    cmd = { "ConformInfo" },
    opts = {
        formatters_by_ft = {
            python = { "isort", "black" },      -- Sorts your imports, then formats the code
            c = { "clang-format" },
            cpp = { "clang-format" },
            go = { "goimports", "gofmt" },      -- Adds missing Go imports automatically!
            javascript = { "prettier" },
            typescript = { "prettier" },
            rust = { "rustfmt" },
            dart = { "dart_format" },
            lua = { "stylua" },
        },
        formatters = {
            black = {
                prepend_args = { "--line-length", "110" },
            },
            isort = {
                prepend_args = { "--line-length", "110" },
            },
        },
        format_on_save = {
            timeout_ms = 500,
            lsp_format = "fallback", -- If a formatter is missing, it asks your LSP to try its best
        },
    },
}
