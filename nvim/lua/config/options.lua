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

-- Clipboard integration (system clipboard integration)
vim.opt.clipboard = "unnamedplus"

-- Forzar el uso de OSC 52 para el portapapeles (ideal para SSH/Contenedores/Zellij)
vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
        ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
        ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
        ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
}

-- Split directions
vim.opt.splitright = true
vim.opt.splitbelow = true
