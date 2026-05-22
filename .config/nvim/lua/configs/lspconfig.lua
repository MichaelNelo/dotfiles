require("nvchad.configs.lspconfig").defaults()

local servers = { "html", "cssls", "serve_d" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers

vim.lsp.config.serve_d = {
  settings = {
    d = {
      dcdServerPath = vim.fn.exepath("dcd-server"),
      dcdClientPath = vim.fn.exepath("dcd-client"),
      aggressiveUpdate = false,
    }
  }
}
