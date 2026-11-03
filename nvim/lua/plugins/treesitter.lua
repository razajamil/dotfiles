-- Keep treesitter highlighting OFF for markdown (see lua/config/autocmds.lua).
-- LazyVim's own FileType autocmd calls vim.treesitter.start() after ours, so
-- the stop in autocmds.lua alone was undone. This tells LazyVim to skip it.
return {
  "nvim-treesitter/nvim-treesitter",
  opts = { highlight = { disable = { "markdown" } } },
}
