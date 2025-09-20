-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  "neovim/nvim-lspconfig",
  config = function()
    local lspconfig = require("lspconfig")

    -- Advertise completion capabilities to LSPs (integrates with nvim-cmp if present)
    local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = ok and cmp_nvim_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()

    -- Lua (Neovim config)
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } }, -- don't warn on 'vim'
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    })

    -- Go
    lspconfig.gopls.setup({
      capabilities = capabilities,
      -- settings = { gopls = { hints = { assignVariableTypes = true, compositeLiteralFields = true } } },
    })

    -- Rust
    lspconfig.rust_analyzer.setup({
      capabilities = capabilities,
      -- settings = { ["rust-analyzer"] = { cargo = { allFeatures = true } } },
    })

    -- Zig
    lspconfig.zls.setup({
      capabilities = capabilities,
    })

    -- TypeScript / JavaScript (was 'tsserver')
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
      -- Example inlay hints (server must support them)
      -- settings = {
      --   typescript = { inlayHints = { includeInlayParameterNameHints = "all" } },
      --   javascript = { inlayHints = { includeInlayParameterNameHints = "all" } },
      -- },
    })
    -- could switch ts_ls to vtsls - would need to add vtsls to flake
    -- lspconfig.vtsls.setup({ capabilities = capabilities })

    -- Python
    lspconfig.pyright.setup({
      capabilities = capabilities,
    })

    -- Nix
    lspconfig.nil_ls.setup({
      capabilities = capabilities,
    })

    -- C/C++ (requires 'clangd' on PATH; pkgs.clang-tools added in flake to provide this)
    lspconfig.clangd.setup({
      capabilities = capabilities,
    })
  end,
}

