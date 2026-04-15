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
        settings = {
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
