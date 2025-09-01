-- which-key: discoverable keymaps popup
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    plugins = { spelling = true },
    window = { border = "rounded" },
    icons = { separator = "➜" },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Group names so <leader> shows helpful sections
    wk.register({
      ["<leader>f"] = { name = "+find" },   -- telescope
      ["<leader>g"] = { name = "+git" },    -- gitsigns / git actions
      ["<leader>l"] = { name = "+lsp" },    -- lsp actions
      ["<leader>t"] = { name = "+toggle" }, -- toggles (wrap, numbers, etc.)
      ["<leader>h"] = { name = "+help" },   -- help or misc
    })
  end,
}

