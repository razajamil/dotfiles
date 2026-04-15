return {
  "akinsho/bufferline.nvim",
  opts = function(_, opts)
    opts.options = opts.options or {}

    opts.options.show_buffer_icons = false
    opts.options.show_buffer_close_icons = false
    opts.options.show_close_icon = false
    opts.options.always_show_bufferline = true
    opts.options.show_tab_indicators = false
    opts.options.indicator = { style = "none" }
    opts.options.tab_size = 1
    opts.options.max_name_length = 16
    opts.options.diagnostics = false
    opts.options.diagnostics_indicator = nil
    opts.options.get_element_icon = function()
      return nil
    end
    opts.options.name_formatter = function(buf)
      local name = buf.name
      local ext = vim.fn.fnamemodify(name, ":e")

      if ext == "lua" or ext == "ts" or ext == "tsx" then
        return vim.fn.fnamemodify(name, ":r")
      end

      return name
    end
  end,
}
