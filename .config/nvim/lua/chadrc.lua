-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

-- Read theme from writable location (Guix/NixOS compatibility)
local function get_theme()
	local theme_file = vim.fn.expand("~/.local/state/nvim/theme.txt")
	local f = io.open(theme_file, "r")
	if f then
		local theme = f:read("*l")
		f:close()
		if theme and theme ~= "" then
			return theme
		end
	end
	return "onedark"
end

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = get_theme(),

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
