-- LSP overrides on top of LazyVim.
--
-- TypeScript: the native TS 7 server (`tsc --lsp`) is selected in
-- lua/config/options.lua with `vim.g.lazyvim_ts_lsp`. Its settings come from
-- LazyVim's `lang.typescript.tsc` extra.
--
-- Formatting runs through conform.nvim (LazyVim default). ESLint is registered
-- by LazyVim's eslint extra as an extra formatter that runs BEFORE conform's
-- prettier, so a save does: ESLint fix-all -> prettier. It also follows the
-- `<leader>uf` / `<leader>uF` auto-format toggles.

---@param root_dir string?
---@return string
local function eslint_bin(root_dir)
  local bin = "vscode-eslint-language-server"
  if root_dir then
    local local_bin = vim.fs.joinpath(root_dir, "node_modules/.bin", bin)
    if vim.fn.executable(local_bin) == 1 then
      return local_bin
    end
  end
  return bin
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints = { enabled = false }
      opts.codelens = { enabled = false }
      opts.servers = opts.servers or {}

      opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
        -- This monorepo uses only eslintrc (no flat config). nvim-lspconfig's
        -- eslint `cmd` is a function, and Neovim does not apply `cmd_env` to
        -- a function `cmd`. So this function starts the server itself and
        -- passes ESLINT_USE_FLAT_CONFIG=false. It keeps the upstream lookup
        -- of a project-local server in node_modules/.bin.
        cmd = function(dispatchers, config)
          return vim.lsp.rpc.start({ eslint_bin(config.root_dir), "--stdio" }, dispatchers, {
            cwd = config.root_dir,
            env = { ESLINT_USE_FLAT_CONFIG = "false" },
          })
        end,
        settings = {
          -- vscode-eslint 3.x reads `useFlatConfig`; older servers read
          -- `experimental.useFlatConfig`. Set both.
          useFlatConfig = false,
          experimental = { useFlatConfig = false },
          workingDirectories = { mode = "auto" },
        },
      })
    end,
  },
}
