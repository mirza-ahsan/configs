return {
    "benlubas/molten-nvim",
    version = "^1.0.0",                  -- Locks version to prevent sudden breaking changes
    dependencies = { "3rd/image.nvim" }, -- Crucial for Ghostty terminal rendering
    build = ":UpdateRemotePlugins",
    init = function()
        -- Core settings optimized for your tiling window manager and terminal
        vim.g.molten_image_provider = "image.nvim"
        vim.g.molten_output_win_max_height = 20
        vim.g.molten_auto_open_output = false
        vim.g.molten_wrap_output = true
        vim.g.molten_virt_text_output = true
        vim.g.molten_virt_lines_off_by_1 = false
    end,
    config = function()
        -- Fast keymaps for your workflow (using localleader, usually ',')
        -- Initializes specifically to your custom AI kernel
        vim.keymap.set(
            "n",
            "<localleader>mi",
            ":MoltenInit AI<CR>",
            { desc = "Initialize Molten for AI Env", silent = true }
        )

        -- Execution commands
        vim.keymap.set("n", "<localleader>e", ":MoltenEvaluateOperator<CR>", { desc = "Run Operator", silent = true })
        vim.keymap.set("n", "<localleader>rl", ":MoltenEvaluateLine<CR>", { desc = "Evaluate Line", silent = true })
        vim.keymap.set(
            "n",
            "<localleader>rc",
            ":MoltenReevaluateCell<CR>",
            { desc = "Re-evaluate Cell", silent = true }
        )
        vim.keymap.set(
            "v",
            "<localleader>r",
            ":<C-u>MoltenEvaluateVisual<CR>gv",
            { desc = "Evaluate Visual Selection", silent = true }
        )

        -- Window management
        vim.keymap.set(
            "n",
            "<localleader>os",
            ":noautocmd MoltenEnterOutput<CR>",
            { desc = "Show Output", silent = true }
        )
        vim.keymap.set("n", "<localleader>oh", ":MoltenHideOutput<CR>", { desc = "Hide Output", silent = true })
        vim.keymap.set("n", "<localleader>md", ":MoltenDelete<CR>", { desc = "Delete Molten Cell", silent = true })
    end,
}
