require "nvchad.options"

-- Enable project-local config (.nvim.lua)
vim.o.exrc = true

-- Bordes redondeados para ventanas flotantes (LSP hover, diagnostics, etc)
vim.o.winborder = "rounded"

  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
