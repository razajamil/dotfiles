return {
  "folke/snacks.nvim",
  opts = {
    gh = {},
    picker = {
      sources = {
        explorer = { hidden = true },
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
