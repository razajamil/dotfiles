-- Colorscheme configuration.
--
-- Active: "lighter" — pulled from github.com/razajamil/lighter.
-- Update with :Lazy update. For local development, uncomment the `dir` below.

return {
  -- "lighter" theme — installed from GitHub.
  {
    "razajamil/lighter",
    lazy = false,
    priority = 1000,
    -- version = "v0.1.0",                    -- pin a release instead of tracking main
    -- dir = "/Users/raza.jamil/dev/lighter", -- use a local checkout for development
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
