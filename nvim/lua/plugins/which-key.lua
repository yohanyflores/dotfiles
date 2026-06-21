return {
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "modern", -- Clean modern style layout
            spec = {
                { "<leader>f", group = "[F]ind / Telescope" },
                { "<leader>c", group = "[C]ode / LSP" },
            },
        },
    }
}
