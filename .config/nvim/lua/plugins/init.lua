return {
  -- Disable NvChad's default file tree (yazi-neotree from zellij replaces it).
  { "nvim-tree/nvim-tree.lua", enabled = false },

  {
    "direnv/direnv.vim",
    event = "VeryLazy"
  },
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = require "configs.treesitter",
  },
  {
    "scalameta/nvim-metals",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "scala", "sbt", "mill", "sc" },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function() vim.fn["mkdp#util#install"]() end,
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_browser = 'C:/Program Files/Zen Browser/zen.exe'
    end,
    ft = { "markdown" },
  },
  {
    "nickjvandyke/opencode.nvim",
    keys = {
      { "<C-a>", mode = { "n", "x" } },
      { "<C-x>", mode = { "n", "x" } },
      { "<C-.>", mode = { "n", "t" } },
      { "go",  mode = { "n", "x" } },
      { "goo", mode = "n" },
      { "<S-C-u>", mode = "n" },
      { "<S-C-d>", mode = "n" },
      { "+", mode = "n" },
      { "-", mode = "n" },
    },
    opts = {},
    config = function()
      vim.g.opencode_opts = {
        server = {
          start = function()
            require("opencode.terminal").open("opencode --port", {
              split = "right",
              width = math.floor(vim.o.columns * 0.42),
            })
          end,
          toggle = function()
            require("opencode.terminal").toggle("opencode --port", {
              split = "right",
              width = math.floor(vim.o.columns * 0.42),
            })
          end,
        },
      }
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
      vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,                          { desc = "Select opencode…" })
      vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end,                          { desc = "Toggle opencode" })

      vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("@this ") end,        { desc = "Add range to opencode", expr = true })
      vim.keymap.set("n",          "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,   { desc = "Scroll opencode up" })
      vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })

      vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
      vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
    end,
  },
}
