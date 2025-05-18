require("lazy").setup({
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "nvimtools/none-ls.nvim" },
  { "nvim-telescope/telescope.nvim" },
})

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "gopls",
    "rust_analyzer",
    "zls",
    "ols",
    "lua_ls",
    "tsserver",
  },
})

local lspconfig = require("lspconfig")
for _, server in ipairs({
  "gopls", "rust_analyzer", "zls", "ols", "lua_ls", "tsserver"
}) do
  lspconfig[server].setup {}
end

require("nvim-treesitter.configs").setup {
  ensure_installed = { "go", "rust", "zig", "odin", "lua", "javascript", "typescript", "c", "cpp" },
  highlight = { enable = true },
}

