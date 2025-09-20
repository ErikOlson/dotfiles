-- ~/.config/nvim/lua/plugins/lsp.lua
-- Uses the new Neovim 0.11+ API: vim.lsp.config()
-- Falls back to lspconfig.setup() automatically on older versions.

return {
  "neovim/nvim-lspconfig",
  config = function()
    -- capabilities (so LSP integrates with nvim-cmp if present)
    local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = ok_cmp and cmp_nvim_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()

    -- Compat shim: prefer the new API, fall back to lspconfig.<server>.setup
    local use_new = vim.lsp and vim.lsp.config
    local configure = use_new and function(server, opts) vim.lsp.config(server, opts) end
      or function(server, opts) require("lspconfig")[server].setup(opts) end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Lua (Neovim config)
    configure("lua_ls", {
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    })

    -- Go
    configure("gopls", {
      capabilities = capabilities,
      -- settings = { gopls = { hints = { assignVariableTypes = true } } },
    })

    -- Rust
    configure("rust_analyzer", {
      capabilities = capabilities,
      -- settings = { ["rust-analyzer"] = { cargo = { allFeatures = true } } },
    })

    -- Zig
    configure("zls", {
      capabilities = capabilities,
    })

    -- TypeScript / JavaScript (was 'tsserver')
    configure("ts_ls", {
      capabilities = capabilities,
      -- settings = {
      --   typescript = { inlayHints = { includeInlayParameterNameHints = "all" } },
      --   javascript = { inlayHints = { includeInlayParameterNameHints = "all" } },
      -- },
    })

    -- Python
    configure("pyright", {
      capabilities = capabilities,
    })

    -- Nix
    configure("nil_ls", {
      capabilities = capabilities,
    })

    -- C/C++  (requires 'clangd' on PATH; add pkgs.clang-tools in your flake)
    configure("clangd", {
      capabilities = capabilities,
    })
  end,
}

