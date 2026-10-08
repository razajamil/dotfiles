return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local base_on_attach = vim.lsp.config.eslint.on_attach

      opts.inlay_hints = { enabled = false }
      opts.codelens = { enabled = false }
      opts.servers = opts.servers or {}
      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        settings = {
          javascript = {
            referencesCodeLens = {
              enabled = false,
              showOnAllFunctions = true,
            },
          },
          typescript = {
            referencesCodeLens = {
              enabled = false,
              showOnAllFunctions = true,
            },
          },
        },
      })
      opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
        -- nvim-lspconfig now defines eslint's `cmd` as a function, and Neovim
        -- ignores `cmd_env` for function commands (see vim/lsp/client.lua). That
        -- silently dropped ESLINT_USE_FLAT_CONFIG, so the server defaulted to
        -- flat config and failed with "Could not find config file" on this
        -- eslintrc-only monorepo. Forcing `cmd` back to a table re-enables
        -- cmd_env so the env var reaches the server again.
        cmd = { "vscode-eslint-language-server", "--stdio" },
        cmd_env = {
          ESLINT_USE_FLAT_CONFIG = "false",
        },
        settings = {
          experimental = { useFlatConfig = false },
          workingDirectories = { mode = "auto" },
          codeActionOnSave = {
            enable = true,
            mode = "all",
          },
        },
        on_attach = function(client, bufnr)
          if base_on_attach then
            base_on_attach(client, bufnr)
          end

          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "LspEslintFixAll",
          })
        end,
      })
    end,
  },
}
