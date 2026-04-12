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
    local koda_green = "#448c27"
    local koda_red = "#aa3731"
    local koda_dim = "#e7e7e7"
    local koda_type = "#708b8d"

    local custom_light_grey = "#bebbbb"

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
      vim.api.nvim_set_hl(0, group, { italic = true, fg = koda_green, bold = true })
    end

    -- Color if/else, for/while, and return statements
    local keyword_overrides = {
      groups = {
        "@keyword.conditional",
        "@keyword.repeat",
        "@keyword.return",
        "Conditional",
        "Repeat",
      },
    }
    for _, group in ipairs(keyword_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { fg = koda_red })
    end

    -- Color import/export keywords
    local import_overrides = {
      groups = {
        "@keyword.import",
        "@keyword.export",
        "Include",
      },
    }
    for _, group in ipairs(import_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { fg = koda_dim })
    end

    -- Color 'type' keyword in type imports (e.g. import type { Foo } from ...)
    local type_qualifier_overrides = {
      groups = {
        "@type.qualifier",
        "@type.qualifier.typescript",
        "@type.qualifier.tsx",
      },
    }
    for _, group in ipairs(type_qualifier_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { fg = koda_type })
    end

    -- Color hidden/ignored files in Snacks explorer
    local explorer_dim_overrides = {
      groups = {
        "SnacksPickerPathHidden",
        "SnacksPickerPathIgnored",
      },
    }
    for _, group in ipairs(explorer_dim_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { fg = custom_light_grey })
    end

    vim.api.nvim_set_hl(0, "LspCodeLens", { fg = custom_light_grey })
    vim.api.nvim_set_hl(0, "LspCodeLensSeparator", { fg = custom_light_grey })

    local flash_overrides = {
      groups = {
        "FlashLabel",
        "FlashCurrent",
      },
    }
    for _, group in ipairs(flash_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { bg = koda_red, fg = "#ffffff", bold = true })
    end
    vim.api.nvim_set_hl(0, "FlashMatch", { bg = "#000000", fg = "#ffffff", bold = true })

    local search_overrides = {
      groups = {
        "Search",
        "CurSearch",
        "IncSearch",
      },
    }
    for _, group in ipairs(search_overrides.groups) do
      vim.api.nvim_set_hl(0, group, { bg = "#000000", fg = "#ffffff", bold = true })
    end

    vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { fg = custom_light_grey })
  end,
})
