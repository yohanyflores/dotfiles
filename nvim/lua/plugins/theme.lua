return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        priority = 1000, -- Load this theme before any other plugins
        config = function()
            require("rose-pine").setup({
                variant = "auto", -- auto, main, moon, or dawn
                dark_variant = "main", -- main, moon, or dawn
                dim_inactive_layouts = false,
                extend_background_behind_templates = true,
                enable = {
                    terminal = true,
                    legacy_bar = false,
                    migrations = true,
                },
                styles = {
                    bold = true,
                    italic = true,
                    transparency = false,
                },
            })
            -- Apply the colorscheme
            vim.cmd("colorscheme rose-pine")
        end,
    }
}
