local has_modern_nvim = vim.fn.has("nvim-0.12.0") == 1

if has_modern_nvim then
    -- Configuración moderna para Neovim >= 0.12.0 (Host)
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
else
    -- Configuración compatible (Legacy) para Neovim < 0.12.0 (Contenedor)
    return {
        {
            "nvim-treesitter/nvim-treesitter",
            branch = "master", -- Forzar la rama antigua compatible con Neovim < 0.12
            build = ":TSUpdate",
            config = function()
                local configs = require("nvim-treesitter.configs")
                configs.setup({
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
                    },
                    indent = { enable = true },
                })
            end,
        }
    }
end
