-- Set mapleader to space before loading lazy.nvim so plugins can use it
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load core options and keymaps
require("config.options")
require("config.keymaps")

-- Load and setup lazy.nvim
require("config.lazy")
