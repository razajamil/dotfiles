return {
  "mfussenegger/nvim-dap",
  optional = true,
  opts = function()
    local dap = require("dap")
    if not dap.adapters["pwa-node"] then
      require("dap").adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
            "${port}",
          },
        },
      }
    end

    if not dap.adapters["node"] then
      dap.adapters["node"] = function(cb, config)
        if config.type == "node" then
          config.type = "pwa-node"
        end
        local nativeAdapter = dap.adapters["pwa-node"]
        if type(nativeAdapter) == "function" then
          nativeAdapter(cb, config)
        else
          cb(nativeAdapter)
        end
      end
    end

    if not dap.adapters["pwa-chrome"] then
      dap.adapters["pwa-chrome"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = {
            LazyVim.get_pkg_path("js-debug-adapter", "/js-debug/src/dapDebugServer.js"),
            "${port}",
          },
        },
      }

      if not dap.adapters["chrome"] then
        dap.adapters["chrome"] = function(cb, config)
          if config.type == "chrome" then
            config.type = "pwa-chrome"
          end
          local nativeAdapter = dap.adapters["pwa-chrome"]
          if type(nativeAdapter) == "function" then
            nativeAdapter(cb, config)
          else
            cb(nativeAdapter)
          end
        end
      end
    end

    local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

    local vscode = require("dap.ext.vscode")
    vscode.type_to_filetypes["node"] = js_filetypes
    vscode.type_to_filetypes["pwa-node"] = js_filetypes

    for _, language in ipairs(js_filetypes) do
      if not dap.configurations[language] then
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end

      table.insert(dap.configurations[language], {
        type = "pwa-chrome",
        request = "launch",
        name = "Launch empty chrome",
        sourceMaps = true,
      })

      table.insert(dap.configurations[language], {
        name = "----- ↓ launch.json configs ↓ -----",
        type = "",
        request = "launch",
      })
    end

    local original_run = dap.run
    dap.run = function(config, opts)
      if config and config.type == "chrome" then
        config.type = "pwa-chrome"
        if config.sourceMaps == nil then
          config.sourceMaps = true
        end
      end
      return original_run(config, opts)
    end
  end,
}
