-- Colorscheme configuration.
--
-- Active: "lighter" — LOCAL checkout at ~/dev/lighter (for development).
-- Edit lua/lighter/palette.lua there, then :LighterReload to see changes.
-- For the published theme, use "razajamil/lighter" instead of dir (see below).

return {
  -- "lighter" theme — LOCAL checkout for development.
  {
    dir = "/Users/raza.jamil/dev/lighter",
    name = "lighter",
    lazy = false,
    priority = 1000,
    -- Published instead: replace the two lines above with  "razajamil/lighter"
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
