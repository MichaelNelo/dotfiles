local M = {}

M.open = function()
  -- Encontrar el root del repositorio git
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]

  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repository", vim.log.levels.WARN)
    return
  end

  -- Dimensiones de la ventana flotante
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Crear buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- Crear ventana flotante
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Lazygit ",
    title_pos = "center",
  })

  -- Ejecutar lazygit en el directorio del repo
  vim.fn.termopen("lazygit", {
    cwd = git_root,
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  -- Entrar en modo insert para interactuar con lazygit
  vim.cmd("startinsert")

  -- Keymap para cerrar con q (en modo normal)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
end

return M
