require "nvchad.autocmds"

-- Patch NvChad theme selector for Guix/NixOS (read-only config)
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local nvchad_utils = require("nvchad.utils")
		local state_dir = vim.fn.expand("~/.local/state/nvim")
		local theme_file = state_dir .. "/theme.txt"

		nvchad_utils.replace_word = function(old, new)
			-- Create state directory if it doesn't exist
			vim.fn.mkdir(state_dir, "p")

			-- Extract theme name from '"theme_name"' format
			local theme_name = new:gsub('"', "")

			-- Write theme to writable location
			local f = io.open(theme_file, "w")
			if f then
				f:write(theme_name)
				f:close()
			end
		end
	end,
	once = true,
})

-- Metals (Scala LSP)
local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "scala", "sbt", "mill", "sc" },
  callback = function()
    require("metals").initialize_or_attach(require "configs.metals")
  end,
  group = nvim_metals_group,
})
