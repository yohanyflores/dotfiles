return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        main = "nvim-treesitter",
        opts = {
            ensure_installed = {
                "lua",
                "vim",
                "vimdoc",
                "query",
                "bash",
                "html",
                "css",
                "python",
                "javascript",
                "typescript",
                "go",
                "java",
                "clojure",
                "sql",
                "markdown",
                "markdown_inline",
            },
            sync_install = false,
            highlight = { 
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
        },
    }
}
