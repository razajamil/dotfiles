return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local diagnostics = {}

      for _, component in ipairs(opts.sections.lualine_c or {}) do
        if type(component) == "table" and component[1] == "diagnostics" then
          diagnostics = { component }
          break
        end
      end

      opts.sections.lualine_c = diagnostics
      opts.sections.lualine_z = {}
    end,
  },
}
