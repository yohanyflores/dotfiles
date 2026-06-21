return {
    {
        "HiPhish/rainbow-delimiters.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            -- The plugin works automatically out of the box by hooking into Treesitter.
            -- No complex manual setup is needed, it will use the theme's colors
            -- to color parentheses, brackets, and braces.
        end,
    }
}
