-- lua/plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.4",
  dependencies = { "nvim-lua/plenary.nvim" },

  -- Lazy triggers
  cmd = "Telescope",  -- :Telescope command loads it
  keys = {
    { "<leader>ff", function() require("telescope.builtin").find_files({ hidden = true }) end, desc = "[F]ind [F]iles" },
    { "<leader>fg", function() require("telescope.builtin").live_grep() end,               desc = "[F]ind with [G]rep" },
    { "<leader>fb", function() require("telescope.builtin").buffers() end,                 desc = "[F]ind [B]uffers" },
    { "<leader>fh", function() require("telescope.builtin").help_tags() end,               desc = "[F]ind [H]elp"    },
  },

  config = function()
    require("telescope").setup({})
  end,
}

