-- ~/.config/nvim/lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "go", "typescript", "python", "bash", "json", "yaml", "toml" },
      highlight = { enable = true },
    })
  end,
}

