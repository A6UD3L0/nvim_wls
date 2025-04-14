-- auto_windows.lua
-- This module automatically opens Windows directories on startup
-- and ensures all file operations prioritize Windows paths

local M = {}

-- Initialize the Windows-first environment
function M.setup()
  local wsl_detector = (function()
    local output = vim.fn.system('uname -r')
    return output:lower():match('microsoft') ~= nil or output:lower():match('wsl') ~= nil
  end)()
  
  -- Only activate in WSL
  if not wsl_detector then
    return
  end
  
  -- Try to get wsl module
  local ok, wsl = pcall(require, "wsl")
  if not ok then
    vim.notify("WSL module not found, Windows integration disabled", vim.log.levels.WARN)
    return
  end
  
  -- Get Windows home
  local win_home = wsl.get_windows_home()
  
  -- Force change to Windows home on startup
  if vim.fn.isdirectory(win_home) == 1 then
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd('cd ' .. win_home)
        vim.notify("Starting in Windows home: " .. win_home, vim.log.levels.INFO)
      end,
      once = true,
    })
  end
  
  -- Ensure Windows paths are prioritized in file operations
  
  -- Telescope Windows priority (if already loaded)
  vim.api.nvim_create_autocmd("User", {
    pattern = "TelescopePreviewerLoaded",
    callback = function()
      if wsl.set_windows_search_paths then
        wsl.set_windows_search_paths()
      end
    end,
    once = true,
  })
  
  -- Create commands for quick Windows navigation
  vim.api.nvim_create_user_command("WindowsHome", function()
    wsl.goto_windows_home()
  end, { desc = "Go to Windows home directory" })
  
  vim.api.nvim_create_user_command("WindowsDesktop", function()
    wsl.goto_windows_desktop()
  end, { desc = "Go to Windows desktop directory" })
  
  vim.api.nvim_create_user_command("WindowsFiles", function()
    wsl.browse_windows_files()
  end, { desc = "Browse Windows files with Telescope" })
  
  -- Add startup autocmd to ensure we never start in Linux directories
  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      local cwd = vim.fn.getcwd()
      -- If we're in a Linux directory that's not /mnt, go to Windows home
      if not cwd:match("^/mnt/") and not cwd:match("^/$") then
        vim.schedule(function()
          wsl.goto_windows_home()
        end)
      end
    end,
  })
  
  -- Override find_files behavior globally to always use Windows home
  if pcall(require, "telescope") and pcall(require, "telescope.builtin") then
    local builtin = require("telescope.builtin")
    -- Save the original find_files
    if not _G._original_find_files then
      _G._original_find_files = builtin.find_files
      
      -- Replace with Windows-prioritizing version
      builtin.find_files = function(opts)
        opts = opts or {}
        if not opts.cwd then
          opts.cwd = win_home
          opts.prompt_title = "Windows Files"
        end
        return _G._original_find_files(opts)
      end
    end
  end
end

return M
