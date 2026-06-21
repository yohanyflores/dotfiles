return {
    {
        "HiPhish/rainbow-delimiters.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            -- Configuración global de rainbow-delimiters
            local rainbow_delimiters = require("rainbow-delimiters")

            vim.g.rainbow_delimiters = {
                -- Estrategia para colorear. 'global' colorea todo el archivo de forma asíncrona.
                strategy = {
                    [""] = rainbow_delimiters.strategy["global"],
                },
                -- Consultas de Treesitter. 'rainbow-delimiters' es la consulta estándar
                -- que busca (), [] y {}.
                query = {
                    [""] = "rainbow-delimiters",
                    lua = "rainbow-blocks",
                },
                -- Lista de colores que ciclan por nivel de anidamiento.
                -- Si quieres cambiar el orden de los colores, reordena esta lista.
                -- Los nombres corresponden a grupos de color definidos por el tema (Rose Pine).
                highlight = {
                    "RainbowDelimiterRed",    -- Nivel 1 (Rosa/Rojo - 'love' de Rose Pine)
                    "RainbowDelimiterYellow", -- Nivel 2 (Dorado/Amarillo - 'gold')
                    "RainbowDelimiterBlue",   -- Nivel 3 (Azul - 'pine')
                    "RainbowDelimiterOrange", -- Nivel 4 (Naranja/Rosa claro - 'rose')
                    "RainbowDelimiterGreen",  -- Nivel 5 (Verde - 'foam')
                    "RainbowDelimiterViolet", -- Nivel 6 (Violeta - 'iris')
                    "RainbowDelimiterCyan",   -- Nivel 7 (Cian - 'foam')
                },
            }
        end,
    }
}
