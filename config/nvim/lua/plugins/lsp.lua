-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require("lspconfig")
    lspconfig.lua_ls.setup({})
    lspconfig.gopls.setup({})
    lspconfig.tsserver.setup({})
    lspconfig.pyright.setup({})
  end,
}

