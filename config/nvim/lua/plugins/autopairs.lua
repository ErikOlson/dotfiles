-- nvim-autopairs: auto-close brackets/quotes + cmp integration
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    fast_wrap = {
      map = "<M-e>",  -- alt-e to fast-wrap selection
    },
    check_ts = true,   -- use treesitter to be smarter
  },
  config = function(_, opts)
    local npairs = require("nvim-autopairs")
    npairs.setup(opts)

    -- integrate with nvim-cmp if present (adds () after function confirm, etc.)
    local ok, cmp = pcall(require, "cmp")
    if ok then
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
}

