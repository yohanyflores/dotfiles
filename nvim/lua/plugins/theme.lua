return {
    {
        "RRethy/base16-nvim",
        priority = 1000, -- Cargar antes de cualquier otro plugin
        config = function()
            -- Configuración de tu paleta personalizada "Dank Colors"
            require("base16-colorscheme").setup({
                base00 = "#131313",
                base01 = "#131313",
                base02 = "#9c99a5",
                base03 = "#9c99a5",
                base04 = "#f3efff",
                base05 = "#faf8ff",
                base06 = "#faf8ff",
                base07 = "#faf8ff",
                base08 = "#ff9fb3",
                base09 = "#ff9fb3",
                base0A = "#d5c6ff",
                base0B = "#a5ffb8",
                base0C = "#e8e1ff",
                base0D = "#d5c6ff",
                base0E = "#dcd0ff",
                base0F = "#dcd0ff",
            })

            -- Ajustes de grupos de resaltado específicos
            vim.api.nvim_set_hl(0, "Visual", {
                bg = "#9c99a5",
                fg = "#faf8ff",
                bold = true,
            })
            vim.api.nvim_set_hl(0, "Statusline", {
                bg = "#d5c6ff",
                fg = "#131313",
            })
            vim.api.nvim_set_hl(0, "LineNr", { fg = "#9c99a5" })
            vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#e8e1ff", bold = true })

            vim.api.nvim_set_hl(0, "Statement", {
                fg = "#dcd0ff",
                bold = true,
            })
            vim.api.nvim_set_hl(0, "Keyword", { link = "Statement" })
            vim.api.nvim_set_hl(0, "Repeat", { link = "Statement" })
            vim.api.nvim_set_hl(0, "Conditional", { link = "Statement" })

            vim.api.nvim_set_hl(0, "Function", {
                fg = "#d5c6ff",
                bold = true,
            })
            vim.api.nvim_set_hl(0, "Macro", {
                fg = "#d5c6ff",
                italic = true,
            })
            vim.api.nvim_set_hl(0, "@function.macro", { link = "Macro" })

            vim.api.nvim_set_hl(0, "Type", {
                fg = "#e8e1ff",
                bold = true,
                italic = true,
            })
            vim.api.nvim_set_hl(0, "Structure", { link = "Type" })

            vim.api.nvim_set_hl(0, "String", {
                fg = "#a5ffb8",
                italic = true,
            })

            vim.api.nvim_set_hl(0, "Operator", { fg = "#f3efff" })
            vim.api.nvim_set_hl(0, "Delimiter", { fg = "#f3efff" })
            vim.api.nvim_set_hl(0, "@punctuation.bracket", { link = "Delimiter" })
            vim.api.nvim_set_hl(0, "@punctuation.delimiter", { link = "Delimiter" })

            vim.api.nvim_set_hl(0, "Comment", {
                fg = "#9c99a5",
                italic = true,
            })

            -- Live Theme Reloader: Vigilante de archivos en vivo
            local current_file_path = vim.fn.stdpath("config") .. "/lua/plugins/theme.lua"
            if not _G._matugen_theme_watcher then
                local uv = vim.uv or vim.loop
                _G._matugen_theme_watcher = uv.new_fs_event()
                _G._matugen_theme_watcher:start(current_file_path, {}, vim.schedule_wrap(function()
                    local new_spec = dofile(current_file_path)
                    if new_spec and new_spec[1] and new_spec[1].config then
                        new_spec[1].config()
                        print("Tema recargado en vivo con éxito 🎨")
                    end
                end))
            end
        end,
    }
}
