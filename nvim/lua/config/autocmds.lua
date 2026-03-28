-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
vim.api.nvim_create_autocmd({ "ColorScheme", "FileType" }, {
  pattern = { "*", "javascriptreact", "typescriptreact" },
  callback = function()
    local sonokai_red = "#f76c7c"
    local sonokai_yellow = "#e3d367"
    local sonokai_orange = "#f3a96a"
    local sonokai_grey = "#82878b"

    local white = "#ffffff"

    local highlight_overrides = {
      -- JSX/TSX tag
      {
        groups = {
          "@tag.tsx",
          "@tag.jsx",
          "@tag.delimiter.tsx",
          "@tag.delimiter.jsx",
          "@tag",
          "@tag.delimiter",
          "@tag.builtin.tsx",

          "@punctuation.special.tsx",
        },
        color = sonokai_red,
      },
      -- Props
      {
        groups = {
          "@tag.attribute.tsx",
          "@tag.attribute.jsx",
          "@tag.attribute",
          "@variable.member.typescript",
          "@variable.member.tsx",
          "@variable.tsx",
          "@type.typescript",
          "@type.tsx",
          "@lsp.type.property.typescriptreact",
          "@lsp.type.property.typescript",
        },
        color = white,
      },
      {
        groups = {
          "@keyword.import.tsx",
          "@keyword.import.typescript",
        },
        color = sonokai_grey,
      },
    }

    for _, override in ipairs(highlight_overrides) do
      for _, group in ipairs(override.groups) do
        vim.api.nvim_set_hl(0, group, { fg = override.color })
      end
    end

    -- Make strings italic
    local italic_overrides = {
      groups = {
        "@string",
        "@string.jsx",
        "@string.tsx",
        "@string.typescript",
        "@string.javascript",
        "String",
        "stringLiteral",
      },
    }
    for _, group in ipairs(italic_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { italic = true, fg = sonokai_yellow })
    end
  end,
})
