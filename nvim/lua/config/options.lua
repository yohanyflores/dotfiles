-- Set line numbering (relative)
vim.opt.number = true
vim.opt.relativenumber = true

-- Tab and indentation settings
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- UI settings
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.laststatus = 3   -- Barra de estado global única al final de la pantalla
vim.opt.showmode = false   -- Ocultar el modo de texto duplicado abajo
vim.opt.ruler = false      -- Desactivar el ruler tradicional para evitar la barra extra inferior

-- Clipboard integration (system clipboard integration)
vim.opt.clipboard = "unnamedplus"

-- Split directions
vim.opt.splitright = true
vim.opt.splitbelow = true
