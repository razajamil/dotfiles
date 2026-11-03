-- Colorscheme configuration.
--
-- Active: "lighter", the published theme from github.com/razajamil/lighter, so it installs the same
-- way on every machine (this one and the dev boxes).

return {
  {
    "razajamil/lighter",
    name = "lighter",
    lazy = false,
    priority = 1000,
    -- config = function()                    -- override colors at load time:
    --   require("lighter").setup({ colors = { line = "#bebbbb" } })
    -- end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "lighter",
    },
  },
}
