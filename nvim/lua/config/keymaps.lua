-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Reveal the current file in macOS Finder
vim.keymap.set("n", "<leader>fo", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file in this buffer", vim.log.levels.WARN)
    return
  end
  vim.ui.open(path, { cmd = { "open", "-R" } })
end, { desc = "Reveal file in Finder" })

-- Copy the current file's absolute path to the clipboard
vim.keymap.set("n", "<leader>fz", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file in this buffer", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy file path (absolute)" })

-- Copy the current file's path relative to the cwd
vim.keymap.set("n", "<leader>fZ", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file in this buffer", vim.log.levels.WARN)
    return
  end
  local rel = vim.fn.fnamemodify(path, ":.")
  vim.fn.setreg("+", rel)
  vim.notify("Copied: " .. rel)
end, { desc = "Copy file path (relative)" })
