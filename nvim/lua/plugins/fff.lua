local function open_buffers_with_fff()
  if require("fff.picker_ui.picker_ui").state.active then
    return
  end

  -- fff bug (c188e7a): a content-index build that is still running when the
  -- index moves to another directory installs its stale index into the new
  -- one, so the buffer grep would find nothing. Only switch when it is done.
  local has_picker, progress = pcall(require("fff.fuzzy").get_scan_progress)
  if has_picker and not progress.is_index_ready then
    vim.notify("FFF is still indexing the project. Try again in a few seconds.", vim.log.levels.INFO)
    return
  end

  local cwd = vim.uv.cwd()
  local tmp_root = vim.fn.stdpath("cache") .. "/fff-open-buffers"
  local path_map = {}

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
      local picker_path = to_picker_path(path)

      if stat and stat.type == "file" and not path_map[picker_path] then
        local copy_path = tmp_root .. "/" .. picker_path
        vim.fn.mkdir(vim.fn.fnamemodify(copy_path, ":h"), "p")
        vim.fn.writefile(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), copy_path)
        path_map[picker_path] = path
      end
    end
  end

  if vim.tbl_isempty(path_map) then
    vim.notify("No open file buffers found", vim.log.levels.INFO)
    vim.fn.delete(tmp_root, "rf")
    return
  end

  -- fff skips hidden paths (.agents/, .github/) and node_modules outside a git
  -- repo, and colours uncommitted files, so the copies go into a committed repo.
  local function git(...)
    local cmd = { "git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false" }
    vim.list_extend(cmd, { "-c", "user.name=fff", "-c", "user.email=fff@localhost", ... })
    vim.system(cmd, { cwd = tmp_root }):wait()
  end

  git("init", "-q")
  git("add", "-A")
  git("commit", "-q", "-m", "open buffers")

  local fff = require("fff")
  local picker_ui = require("fff.picker_ui.picker_ui")
  local search_manager = require("fff.picker_ui.search_manager")
  local file_renderer = require("fff.picker_ui.file_renderer")
  local grep_renderer = require("fff.picker_ui.grep_renderer")
  local original_update_results_sync = search_manager.update_results_sync

  -- An empty query lists the open buffers; any text greps their contents.
  local function update_results_sync(...)
    local state = picker_ui.state
    if state.query == "" then
      state.mode = nil
      state.renderer = file_renderer
    else
      state.mode = "grep"
      state.renderer = grep_renderer
    end

    state.last_status_info = nil
    return original_update_results_sync(...)
  end

  local function restore()
    search_manager.update_results_sync = original_update_results_sync
    picker_ui.update_results_sync = original_update_results_sync
    -- Point the shared fff index back at the project now, so the next `ff`
    -- does not have to start a full re-index when it opens.
    fff.change_indexing_directory(cwd)
    vim.schedule(function()
      vim.fn.delete(tmp_root, "rf")
    end)
  end

  local function open_real_file(item, ctx)
    local path = path_map[item.relative_path]
    if not path then
      return
    end

    local win = require("fff.conf").get().select.select_window(vim.api.nvim_get_current_buf(), ctx.action)
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end

    local open_cmd = ({ split = "split", vsplit = "vsplit", tab = "tabedit" })[ctx.action] or "edit"
    vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(vim.fn.fnamemodify(path, ":.")))
    if ctx.location then
      require("fff.location_utils").jump_to_location(ctx.location)
    end
  end

  search_manager.update_results_sync = update_results_sync
  picker_ui.update_results_sync = update_results_sync

  local ok, err = pcall(fff.live_grep, {
    cwd = tmp_root,
    title = "Open Buffer Contents",
    on_submit = open_real_file,
  })

  local input_buf = picker_ui.state.input_buf
  if not ok or not picker_ui.state.active or not input_buf then
    restore()
    if not ok then
      vim.notify("Failed to open FFF buffers picker: " .. tostring(err), vim.log.levels.ERROR)
    end
    return
  end

  vim.api.nvim_create_autocmd("BufWipeout", { buffer = input_buf, once = true, callback = restore })
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
    -- A full index of the monorepo costs ~4.5s CPU and up to ~200MB per session,
    -- so only project sessions (`nvim` or `nvim <dir>`) build it at startup; a
    -- git commit editor or a one-file edit does not. Then the first `ff`/`fg`
    -- does not wait for the walk and the content index.
    init = function()
      vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        callback = function()
          if vim.fn.argc() == 0 or vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
            vim.defer_fn(function()
              require("fff.core").ensure_initialized()
            end, 200)
          end
        end,
      })
    end,
    -- NOTE: these must live under `opts` so lazy.nvim actually calls
    -- `require("fff").setup(opts)` (which sets `vim.g.fff`). As bare spec keys
    -- they were silently ignored, leaving `vim.g.fff` nil. `lazy_sync = true`
    -- stops plugin/fff.lua from indexing in every session at UIEnter; `init`
    -- above starts it only for project sessions. (This setting first fixed
    -- `MDB_READERS_FULL` across concurrent sessions; fff fixed that upstream in
    -- #775 and #785.)
    opts = {
      lazy_sync = true,
      max_threads = 8,
      -- Default is `info`, which writes a record per keystroke while the picker
      -- is open and keeps 20 session log files. That was ~30MB of churn on disk
      -- for no benefit outside debugging.
      logging = {
        log_level = "warn",
        retain_runs = 3,
      },
      git = {
        status_text_color = true,
      },
      -- Microsoft Defender scans every file open that it has not seen before
      -- (~8ms each), so in a new worktree or after a pull the content index
      -- takes 40s+ to build. Until it is ready, grep reads files on the UI
      -- thread, and without this a query with no match reads every file.
      grep = {
        enforce_time_budget = true,
      },
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
              modes = { "plain", "regex", "fuzzy" },
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
