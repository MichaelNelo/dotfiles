require "nvchad.mappings"

-- nvim-tree is disabled; drop the mappings NvChad sets for it.
pcall(vim.keymap.del, "n", "<C-n>")
pcall(vim.keymap.del, "n", "<leader>e")

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Terminal mode: salir al modo normal con <C-n>
map("t", "<C-n>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Lazygit
map("n", "<leader>tg", function() require("configs.lazygit").open() end, { desc = "Open Lazygit" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
