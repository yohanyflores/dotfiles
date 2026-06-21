return {
    -- 1. Auto-pairs (Cierre automático de paréntesis, llaves, comillas, etc.)
    {
        "echasnovski/mini.pairs",
        event = "InsertEnter",
        opts = {},
    },

    -- 2. Surround (Añadir, cambiar y borrar envoltorios rápidamente)
    {
        "echasnovski/mini.surround",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            mappings = {
                add = "sa",            -- Añadir envoltorio
                delete = "sd",         -- Borrar envoltorio
                find = "sf",           -- Buscar envoltorio adelante
                find_left = "sF",      -- Buscar envoltorio atrás
                highlight = "sh",      -- Resaltar envoltorio
                replace = "sr",        -- Reemplazar envoltorio
                update_n_lines = "sn", -- Cambiar número de líneas consideradas
            },
        },
    },
}
