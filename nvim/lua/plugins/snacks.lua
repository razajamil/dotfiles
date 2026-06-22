return {
  "folke/snacks.nvim",
  opts = {
    gh = {},
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          -- `o` (built-in) opens folders in Finder & files in their default app.
          -- `O` reveals/selects the item in macOS Finder (`open -R`).
          actions = {
            finder_reveal = function(_, item)
              if item then
                vim.ui.open(item.file, { cmd = { "open", "-R" } })
              end
            end,
          },
          win = { list = { keys = { ["O"] = "finder_reveal" } } },
        },
      },
    },
  },
  keys = {
    -- Disable file search keys because we use fff.nvim for that
    { "<leader>ff", mode = { "n" }, false },
    { "<leader>fF", mode = { "n" }, false },
    { "<leader><leader>", mode = { "n" }, false },
    { "<leader>fg", mode = { "n" }, false },
    { "<leader>fc", mode = { "n" }, false },

    -- Disable grep keys because we use fff.nvim for that
    { "<leader>/", mode = { "n" }, false },
  },
}
