-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- test
-- vim.lsp.set_log_level("debug")

vim.opt.showtabline = 2

-- Disable swapfiles. Avoids the W325 "swapfile from another Nvim process"
-- warnings and the pile-up of orphaned .swp files across herdr worktrees.
-- Trade-off: no crash recovery of unsaved changes (undofile still persists undo).
vim.opt.swapfile = false

-- Keep LSP file logging OFF by default.
-- vim/lsp/log.lua does a synchronous `write()` + `flush()` on the main loop for
-- every record, so a chatty server stalls the UI on each message. lsp.log had
-- reached 366MB / ~1M records; Neovim only warns past 1GB, so nothing flagged
-- it. To debug a server: `:lua vim.lsp.log.set_level("warn")`, reproduce, then
-- `:LspLog` — and set it back to OFF (or restart) afterwards.
require("vim.lsp.log").set_level(vim.log.levels.OFF)

-- LazyVim's eslint extra registers eslint as a format-on-save formatter, and
-- lua/plugins/lsp.lua already runs `LspEslintFixAll` on BufWritePre. Both are
-- blocking round-trips to the same server, so every save paid for ESLint twice
-- on this monorepo. Keep the explicit fixAll; drop LazyVim's duplicate.
vim.g.lazyvim_eslint_auto_format = false
