local function open_buffers_with_fff()
  local cwd = vim.uv.cwd()
  local tmp_root = vim.fn.stdpath("cache") .. "/fff-open-buffers"
  local path_map = {}
  local seen_paths = {}

  local function to_picker_path(path)
    if vim.startswith(path, cwd .. "/") then
      return path:sub(#cwd + 2)
    end

    return "__external__/" .. path:gsub("^/", "")
  end

  vim.fn.delete(tmp_root, "rf")
  vim.fn.mkdir(tmp_root, "p")

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == "" then
      local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
      local stat = path ~= "" and vim.uv.fs_stat(path) or nil

      if stat and stat.type == "file" and not seen_paths[path] then
        seen_paths[path] = true

        local picker_path = tmp_root .. "/" .. to_picker_path(path)
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        vim.fn.mkdir(vim.fn.fnamemodify(picker_path, ":h"), "p")
        vim.fn.writefile(lines, picker_path)
        path_map[picker_path] = path
      end
    end
  end

  if vim.tbl_isempty(path_map) then
    vim.notify("No open file buffers found", vim.log.levels.INFO)
    vim.fn.delete(tmp_root, "rf")
    return
  end

  local picker_ui = require("fff.picker_ui")
  local file_renderer = require("fff.file_renderer")
  local grep_renderer = require("fff.grep.grep_renderer")
  local original_select = picker_ui.select
  local original_close = picker_ui.close
  local original_update_results_sync = picker_ui.update_results_sync
  local restored = false

  local function restore()
    if restored then
      return
    end

    restored = true
    picker_ui.select = original_select
    picker_ui.close = original_close
    picker_ui.update_results_sync = original_update_results_sync
    vim.schedule(function()
      vim.fn.delete(tmp_root, "rf")
    end)
  end

  picker_ui.update_results_sync = function(...)
    if picker_ui.state.query == "" then
      picker_ui.state.mode = nil
      picker_ui.state.renderer = file_renderer
    else
      picker_ui.state.mode = "grep"
      picker_ui.state.renderer = grep_renderer
    end

    picker_ui.state.last_status_info = nil
    return original_update_results_sync(...)
  end

  picker_ui.select = function(action)
    local item = picker_ui.state.filtered_items[picker_ui.state.cursor]
    if item and path_map[item.path] then
      item.path = path_map[item.path]
    end

    local ok, result = pcall(original_select, action)
    if not ok then
      restore()
      error(result)
    end

    return result
  end

  picker_ui.close = function(...)
    local ok, result = pcall(original_close, ...)
    restore()

    if not ok then
      error(result)
    end

    return result
  end

  local ok, err = pcall(function()
    require("fff").live_grep({
      cwd = tmp_root,
      title = "Open Buffer Contents",
    })
  end)

  if not ok then
    restore()
    vim.notify("Failed to open FFF buffers picker: " .. err, vim.log.levels.ERROR)
  end
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      -- this will download prebuild binary or try to use existing rustup toolchain to build from source
      -- (if you are using lazy you can use gb for rebuilding a plugin if needed)
      require("fff.download").download_or_build_binary()
    end,
    -- if you are using nixos
    -- build = "nix run .#release",
    -- opts = { -- (optional)
    --   debug = {
    --     enabled = true, -- we expect your collaboration at least during the beta
    --     show_scores = true, -- to help us optimize the scoring system, feel free to share your scores!
    --   },
    -- },
    -- No need to lazy-load with lazy.nvim.
    -- This plugin initializes itself lazily.
    lazy = false,
    lazy_sync = false,
    max_threads = 8,
    git = {
      status_text_color = true,
    },
    keys = {
      {
        "ff", -- try it if you didn't it is a banger keybinding for a picker
        function()
          require("fff").find_files()
        end,
        desc = "FFFind files",
      },
      {
        "<leader><leader>", -- try it if you didn't it is a banger keybinding for a picker
        function()
          require("fff").find_files()
        end,
        desc = "FFFind files",
      },
      {
        "fg",
        function()
          require("fff").live_grep({
            grep = {
              modes = { "plain", "fuzzy" },
              smart_case = true,
            },
          })
        end,
        desc = "Live fffuzy grep",
      },
      {
        "fc",
        function()
          require("fff").live_grep({ query = vim.fn.expand("<cword>") })
        end,
        desc = "Search current word",
      },
      {
        "<leader>fb",
        open_buffers_with_fff,
        desc = "FFF grep open buffers",
      },
    },
  },
}
