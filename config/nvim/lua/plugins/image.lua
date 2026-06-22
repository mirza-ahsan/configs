return {
    "3rd/image.nvim",
    config = function()
        require("image").setup({
            backend = "kitty", -- Ghostty fully supports the Kitty protocol
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" }, -- Molten outputs often render in markdown hover windows
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = 100,
            max_height_window_percentage = 100,
            window_overlap_clear_enabled = false,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
            editor_only_render_when_focused = false,
            tmux_show_only_in_active_window = false,
        })
    end,
}
