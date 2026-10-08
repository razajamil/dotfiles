-- nvim-lspconfig's tailwindcss `root_dir` lists `.git` as a root marker (an
-- accommodation for Tailwind v4, which no longer needs a config file). So the
-- server attaches in EVERY git repo the moment a js/ts/css/markdown buffer
-- opens — including repos with no Tailwind at all.
--
-- In this monorepo it then walked all ~210 tsconfig files (plus ~925 more
-- across the herdr worktrees) hunting for a config, failed to resolve each
-- workspace `extends`, and emitted a multi-KB stack trace per file. Every one
-- of those reaches lsp.log through a synchronous write+flush on the main loop
-- (see runtime/lua/vim/lsp/log.lua), which is why editing degraded over time.
--
-- Require a genuine Tailwind/PostCSS marker instead. `workspace_required` is
-- already true upstream, so not calling `on_dir` simply means no attach.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.tailwindcss = vim.tbl_deep_extend("force", opts.servers.tailwindcss or {}, {
        root_dir = function(bufnr, on_dir)
          local markers = {
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.mjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.mjs",
            "postcss.config.ts",
            "theme/static_src/tailwind.config.js",
            "theme/static_src/tailwind.config.cjs",
            "theme/static_src/tailwind.config.mjs",
            "theme/static_src/tailwind.config.ts",
            "theme/static_src/postcss.config.js",
          }

          local fname = vim.api.nvim_buf_get_name(bufnr)
          markers = require("lspconfig.util").insert_package_json(markers, "tailwindcss", fname)

          local found = vim.fs.find(markers, { path = fname, upward = true })[1]
          if found then
            on_dir(vim.fs.dirname(found))
          end
        end,
      })
    end,
  },
}
