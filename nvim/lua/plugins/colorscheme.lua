return {
  {
    "oskarnurm/koda.nvim",
    priority = 1000,
    opts = function()
      local glade = require("koda.palette.glade")

      return {
        colors = {
          line = "#bebbbb",
        },
      }
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "koda-glade",
    },
  },
}
