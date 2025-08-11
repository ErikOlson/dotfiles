-- ~/.config/nvim/lua/plugins/surround.lua
return {
  "echasnovski/mini.surround",
  version = false, -- always use latest
  event = "VeryLazy",
  opts = {
    mappings = {
      add = "sa",      -- Add surrounding
      delete = "sd",   -- Delete surrounding
      replace = "sr",  -- Replace surrounding
    },
  },
  config = function(_, opts)
    require("mini.surround").setup(opts)
  end,
}

