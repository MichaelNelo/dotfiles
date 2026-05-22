local metals_config = require("metals").bare_config()

metals_config.settings = {
  showImplicitArguments = true,
  excludedPackages = { "akka.actor.typed.javadsl", "com.github.swagger.akka.javadsl" },
  metalsBinaryPath = vim.g.metals_binary_path,
}

metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Interceptar mensajes de progress y normalizar percentage al rango [0, 100]
local original_handler = vim.lsp.handlers["$/progress"]
metals_config.handlers = {
  ["$/progress"] = function(err, result, ctx, config)
    if result and result.value and result.value.percentage then
      result.value.percentage = result.value.percentage % 100
    end
    if original_handler then
      return original_handler(err, result, ctx, config)
    end
  end,
}

return metals_config
