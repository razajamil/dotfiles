return {
  {
    "sainnhe/sonokai",
    config = function()
      vim.g.sonokai_style = "maia"
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "sonokai",
    },
  },
}
