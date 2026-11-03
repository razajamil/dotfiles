-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

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
vim.lsp.log.set_level(vim.log.levels.OFF)

-- TypeScript LSP: the native TS 7 server (`tsc --lsp`, installed by Mason).
-- A project-local tsc older than 7 is skipped, so projects that still pin
-- TypeScript 5/6 also use this server. To go back, set this to "vtsls".
vim.g.lazyvim_ts_lsp = "tsc"

-- ESLint fix-all on save comes from LazyVim's eslint extra (it runs before
-- prettier and follows the <leader>uf toggle). See lua/plugins/lsp.lua.
