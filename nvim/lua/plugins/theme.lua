return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        priority = 1000, -- Cargar antes de cualquier otro plugin
        config = function()
            require("rose-pine").setup({
                variant = "auto", -- auto, main, moon, o dawn
                dark_variant = "main", -- main, moon, o dawn
                dim_inactive_split = false,
                extend_background_behind_templates = true,
                enable = {
                    terminal = true,
                    legacy_bar = false,
                    migrations = true, -- Manejar opciones obsoletas automáticamente
                },
                styles = {
                    bold = true,
                    italic = true,
                    transparency = false,
                },
            })

            vim.cmd("colorscheme rose-pine")
        end,
    }
}
