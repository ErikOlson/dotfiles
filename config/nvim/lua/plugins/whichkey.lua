-- ~/.config/nvim/lua/plugins/which-key.lua
return {
  "folke/which-key.nvim",
  event = "VeryLazy",

  opts = {
    win = {
      border = "single",
      no_overlap = true,
    },
    plugins = {
      spelling = false, -- quiet things down a bit
    },
  },

  -- Lazy will pass `opts` to setup; we then add group labels via wk.add (new spec).
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    wk.add({
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git" },
      { "<leader>h", group = "help" },
      { "<leader>l", group = "lsp" },
      { "<leader>t", group = "toggle" },
    })
  end,
}

-- Optional note:
-- If you want to silence the "mini.icons not installed" warning,
-- add this plugin somewhere in your specs:
-- { "echasnovski/mini.icons", version = false, opts = {} }

