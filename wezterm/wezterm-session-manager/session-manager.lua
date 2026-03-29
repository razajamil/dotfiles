local wezterm = require("wezterm")
local session_manager = {}
local target_triple = wezterm.target_triple

--- Returns true if running on Windows.
local function is_windows()
  return target_triple and target_triple:find("windows") ~= nil
end

--- Returns true if running on Linux.
local function is_linux()
  return target_triple and target_triple:find("linux") ~= nil
end

--- Returns true if running on macOS.
local function is_macos()
  return target_triple and target_triple:find("darwin") ~= nil
end

--- Extracts a clean filesystem path from a cwd URL string.
-- Handles file:// URLs and already-clean paths.
-- @param url_str string: A file:// URL or filesystem path
-- @return string: The filesystem path
local function parse_cwd_url(url_str)
  if not url_str or url_str == "" or url_str == "nil" then
    return wezterm.home_dir
  end

  -- Already a clean path (starts with / on Unix or drive letter on Windows)
  if url_str:sub(1, 1) == "/" or url_str:match("^%a:\\") then
    return url_str
  end

  -- Parse file:// URL
  if is_windows() then
    -- file:///C:/path/to/dir -> C:/path/to/dir
    return url_str:gsub("file:///", "")
  else
    -- file://hostname/path/to/dir -> /path/to/dir
    -- file:///path/to/dir -> /path/to/dir
    return url_str:gsub("^file://[^/]*", "")
  end
end

--- Gets a clean filesystem path for a pane's current working directory.
-- Handles Url objects (WezTerm >= 20230320) and falls back to string parsing.
-- @param pane: The pane object
-- @return string: The filesystem path
local function get_pane_cwd(pane)
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri == nil then
    return wezterm.home_dir
  end

  -- Modern WezTerm returns a Url object with a file_path property
  if type(cwd_uri) ~= "string" then
    if cwd_uri.file_path then
      return cwd_uri.file_path
    end
  end

  -- Fallback: parse URL string (older WezTerm or unexpected type)
  return parse_cwd_url(tostring(cwd_uri))
end

--- Gets the foreground process name for a pane, or nil if unavailable.
--- Uses cascading detection: process API first, then pane title fallback
--- for mux domain panes where process info is unavailable.
-- @param pane: The pane object
-- @return string or nil: The process name/path
local function get_pane_process(pane)
  -- Method 1: get_foreground_process_name (works for local domain panes only)
  local success, process = pcall(function()
    return pane:get_foreground_process_name()
  end)
  if success and process and process ~= "" then
    return process
  end

  -- Method 2: Infer from pane title (fallback for mux domain panes).
  -- Programs like nvim set the terminal title via OSC 2 escape sequences,
  -- which IS available through the mux protocol even when process info is not.
  local title_success, title = pcall(function()
    return pane:get_title()
  end)
  if title_success and title and title ~= "" then
    -- Known TUI programs we want to detect and potentially restore.
    -- This list is intentionally inlined here because is_restorable_process
    -- is defined later in the file and Lua local scoping prevents referencing it.
    local known_programs = {
      "nvim", "vim", "vi",
      "htop", "btop", "top",
      "lazygit", "lazydocker",
    }
    -- Extract the first word and strip path components (e.g. /usr/bin/nvim -> nvim)
    local first_word = title:match("^(%S+)")
    if first_word then
      local basename = first_word:match("[^/\\]+$") or first_word
      for _, prog in ipairs(known_programs) do
        if basename == prog then
          return prog
        end
      end
    end
  end

  return nil
end

--- Checks if a process name looks like a shell.
-- @param process_name string: The process name/path to check
-- @return boolean: true if it appears to be a shell
local function is_shell(process_name)
  if not process_name then
    return true -- Assume shell if unknown
  end
  local name = process_name:match("[^/\\]+$") or process_name
  local shells = { "bash", "zsh", "fish", "sh", "dash", "ksh", "tcsh", "csh",
    "nu", "nushell", "cmd.exe", "powershell.exe", "pwsh.exe", "pwsh" }
  for _, shell in ipairs(shells) do
    if name == shell then
      return true
    end
  end
  return false
end

--- Extracts the binary name from a full process path.
-- @param process_path string: A full path like "/opt/homebrew/bin/nvim"
-- @return string: The binary name, e.g. "nvim"
local function get_process_binary_name(process_path)
  if not process_path or process_path == "" then
    return ""
  end
  return process_path:match("[^/\\]+$") or process_path
end

--- Checks if a process binary name is in the whitelist of restorable TUI programs.
-- @param process_path string: The full process path or binary name
-- @return boolean: true if the process should be relaunched on restore
local function is_restorable_process(process_path)
  local name = get_process_binary_name(process_path)
  local restorable = {
    "nvim", "vim", "vi",
    "htop", "btop", "top",
    "lazygit", "lazydocker",
  }
  for _, prog in ipairs(restorable) do
    if name == prog then
      return true
    end
  end
  return false
end

--- Retrieves the current workspace data from the active window.
-- @param window: The GUI window object
-- @return table or nil: The workspace data table
local function retrieve_workspace_data(window)
  local workspace_name = window:active_workspace()
  local workspace_data = {
    name = workspace_name,
    tabs = {}
  }

  -- Iterate over tabs in the current window
  for _, tab in ipairs(window:mux_window():tabs()) do
    local tab_data = {
      tab_id = tostring(tab:tab_id()),
      tab_title = tab:get_title(),
      panes = {}
    }

    -- Iterate over panes in the current tab
    for _, pane_info in ipairs(tab:panes_with_info()) do
      local cwd = get_pane_cwd(pane_info.pane)
      local process = get_pane_process(pane_info.pane)

      table.insert(tab_data.panes, {
        pane_id = tostring(pane_info.pane:pane_id()),
        index = pane_info.index,
        is_active = pane_info.is_active,
        is_zoomed = pane_info.is_zoomed,
        left = pane_info.left,
        top = pane_info.top,
        width = pane_info.width,
        height = pane_info.height,
        pixel_width = pane_info.pixel_width,
        pixel_height = pane_info.pixel_height,
        cwd = cwd,
        tty = process or ""
      })
    end

    table.insert(workspace_data.tabs, tab_data)
  end

  return workspace_data
end

--- Saves data to a JSON file.
-- @param data table: The workspace data to be saved.
-- @param file_path string: The file path where the JSON file will be saved.
-- @return boolean: true if saving was successful, false otherwise.
local function save_to_json_file(data, file_path)
  if not data then
    wezterm.log_info("No workspace data to save.")
    return false
  end

  local file = io.open(file_path, "w")
  if file then
    file:write(wezterm.json_encode(data))
    file:close()
    return true
  else
    wezterm.log_error("Failed to open file for writing: " .. file_path)
    return false
  end
end

--- Loads data from a JSON file.
-- @param file_path string: The file path from which the JSON data will be loaded.
-- @return table or nil: The loaded data as a Lua table, or nil if loading failed.
local function load_from_json_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    wezterm.log_info("State file not found: " .. file_path)
    return nil
  end

  local file_content = file:read("*a")
  file:close()

  local success, data = pcall(wezterm.json_parse, file_content)
  if not success or not data then
    wezterm.log_error("Failed to parse JSON from: " .. file_path)
    return nil
  end
  return data
end

--- Recreates the workspace based on the provided data.
-- @param window: The GUI window object
-- @param workspace_data table: The data structure containing the saved workspace state.
-- @return boolean: true if recreation was successful
local function recreate_workspace(window, workspace_data)
  if not workspace_data or not workspace_data.tabs or #workspace_data.tabs == 0 then
    wezterm.log_info("Invalid or empty workspace data provided.")
    return false
  end

  local tabs = window:mux_window():tabs()

  if #tabs ~= 1 or #tabs[1]:panes() ~= 1 then
    wezterm.log_info(
      "Restoration can only be performed in a window with a single tab and a single pane, to prevent accidental data loss.")
    return false
  end

  local initial_pane = window:active_pane()
  local foreground_process = get_pane_process(initial_pane)

  -- Close the initial pane if it's running a shell
  if is_shell(foreground_process) then
    initial_pane:send_text("exit\r")
  else
    wezterm.log_info("Active program detected in initial pane. Skipping exit command.")
  end

  -- Collect deferred operations: tab renames and process relaunches.
  -- These are applied after all tabs/panes are created via call_after,
  -- so the mux server has time to settle and shells can initialize.
  local tabs_to_rename = {}
  local panes_to_relaunch = {}

  -- Recreate tabs and panes from the saved state
  for _, tab_data in ipairs(workspace_data.tabs) do
    if not tab_data.panes or #tab_data.panes == 0 then
      wezterm.log_info("Skipping tab with no panes.")
      goto continue_tab
    end

    -- Resolve CWD for the first pane in this tab (handles both old URL and new path formats)
    local first_cwd = parse_cwd_url(tab_data.panes[1].cwd)

    local new_tab, first_pane, _ = window:mux_window():spawn_tab({ cwd = first_cwd })
    if not new_tab then
      wezterm.log_error("Failed to create a new tab.")
      break
    end

    -- Queue tab title for deferred restoration (avoids flickering in mux contexts)
    if tab_data.tab_title and tab_data.tab_title ~= "" then
      table.insert(tabs_to_rename, { tab = new_tab, title = tab_data.tab_title })
    end

    -- Track pane objects: first pane was created by spawn_tab
    local pane_objects = { first_pane }

    -- Recreate additional panes within this tab
    for j, pane_data in ipairs(tab_data.panes) do
      if j == 1 then
        -- First pane already created with spawn_tab
        goto continue_pane
      end

      local direction = "Right"
      if pane_data.left == tab_data.panes[j - 1].left then
        direction = "Bottom"
      end

      local pane_cwd = parse_cwd_url(pane_data.cwd)

      -- Split from the active pane of the tab
      local active = new_tab:active_pane()
      if not active then
        wezterm.log_error("Failed to get active pane for splitting.")
        break
      end

      local new_pane = active:split({
        direction = direction,
        cwd = pane_cwd,
      })

      if not new_pane then
        wezterm.log_error("Failed to split pane.")
        break
      end

      table.insert(pane_objects, new_pane)

      ::continue_pane::
    end

    -- Queue restorable processes for each pane in this tab
    for j, pane_data in ipairs(tab_data.panes) do
      if pane_objects[j] and is_restorable_process(pane_data.tty) then
        local binary = get_process_binary_name(pane_data.tty)
        table.insert(panes_to_relaunch, { pane = pane_objects[j], cmd = binary })
      end
    end

    ::continue_tab::
  end

  -- Defer tab renames and process relaunches so the mux server and shells
  -- have time to settle after the burst of spawn_tab/split calls above.
  -- This follows the same pattern workmux uses for deferred WezTerm operations.
  wezterm.time.call_after(0.5, function()
    -- Batch-apply all tab titles
    for _, entry in ipairs(tabs_to_rename) do
      entry.tab:set_title(entry.title)
    end

    -- Relaunch saved processes (shells have had time to initialize)
    for _, entry in ipairs(panes_to_relaunch) do
      entry.pane:send_text(entry.cmd .. "\r")
    end
  end)

  wezterm.log_info("Workspace recreated with new tabs and panes based on saved state.")
  return true
end

--- Restores the saved state for the current workspace.
-- Loads the JSON file matching the current workspace name and recreates the layout.
function session_manager.restore_state(window)
  local workspace_name = window:active_workspace()
  local file_path = wezterm.home_dir
      .. "/.config/wezterm/wezterm-session-manager/wezterm_state_"
      .. workspace_name
      .. ".json"

  local workspace_data = load_from_json_file(file_path)
  if not workspace_data then
    window:toast_notification("WezTerm Session Manager",
      "No saved state found for workspace: " .. workspace_name, nil, 4000)
    return
  end

  if recreate_workspace(window, workspace_data) then
    window:toast_notification("WezTerm Session Manager",
      "Workspace restored: " .. workspace_name, nil, 4000)
  else
    window:toast_notification("WezTerm Session Manager",
      "Failed to restore workspace: " .. workspace_name, nil, 4000)
  end
end

--- Allows selection of which workspace to load (not yet implemented).
function session_manager.load_state(window)
  -- TODO: Implement workspace selection UI
  window:toast_notification("WezTerm Session Manager",
    "Load session is not yet implemented.", nil, 4000)
end

--- Saves the current workspace state to a JSON file.
function session_manager.save_state(window)
  local data = retrieve_workspace_data(window)
  if not data then
    window:toast_notification("WezTerm Session Manager",
      "Failed to collect workspace data.", nil, 4000)
    return
  end

  local file_path = wezterm.home_dir
      .. "/.config/wezterm/wezterm-session-manager/wezterm_state_"
      .. data.name
      .. ".json"

  if save_to_json_file(data, file_path) then
    window:toast_notification("WezTerm Session Manager",
      "Workspace saved: " .. data.name, nil, 4000)
  else
    window:toast_notification("WezTerm Session Manager",
      "Failed to save workspace: " .. data.name, nil, 4000)
  end
end

return session_manager
