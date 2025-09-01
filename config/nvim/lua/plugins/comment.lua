return {
  "echasnovski/mini.comment",
  version = false,
  event = "VeryLazy",
  config = function()
    require("mini.comment").setup()

    -- IntelliJ-style comment toggle
    -- Leader + / works everywhere
    vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Toggle comment (line)" })
    vim.keymap.set("v", "<leader>/", "gc",  { remap = true, desc = "Toggle comment (selection)" })

    -- GUI Neovim apps (only works if Cmd passes through)
    vim.keymap.set("n", "<D-/>", "gcc", { remap = true, desc = "Toggle comment (line)" })
    vim.keymap.set("v", "<D-/>", "gc",  { remap = true, desc = "Toggle comment (selection)" })
  end,
}

