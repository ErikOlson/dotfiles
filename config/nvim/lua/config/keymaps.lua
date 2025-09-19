-- ~/.config/nvim/lua/config/keymaps.lua
vim.g.mapleader = " "

--vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, {})
--vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, {})
--vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, {})
--vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, {})

vim.keymap.set("n", "<leader>ll", "<cmd>Lazy<CR>", { desc = "Open Lazy UI" })
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
vim.keymap.set("n", "<leader>-", "<cmd>Ex<CR>", { desc = "Explore the directory" })

