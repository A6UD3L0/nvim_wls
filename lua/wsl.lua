-- WSL-specific utilities and helpers
local M = {}

-- Detect if running in WSL
M.is_wsl = function()
  local output = vim.fn.system('uname -r')
  return output:lower():match('microsoft') ~= nil or output:lower():match('wsl') ~= nil
end

-- Convert WSL path to Windows path
M.to_windows_path = function(path)
  if path:match('^/mnt/([a-zA-Z])/(.*)$') then
    local drive, rest = path:match('^/mnt/([a-zA-Z])/(.*)')
    return drive:upper() .. ':\\' .. rest:gsub('/', '\\')
  end
  return path
end

-- Convert Windows path to WSL path
M.to_wsl_path = function(path)
  if path:match('^([a-zA-Z]):(.*)$') then
    local drive, rest = path:match('^([a-zA-Z]):(.*)')
    return '/mnt/' .. drive:lower() .. rest:gsub('\\', '/')
  end
  return path
end

-- Open current file/folder in Windows Explorer
M.open_in_explorer = function()
  local path = vim.fn.expand('%:p')
  local winpath = M.to_windows_path(path)
  
  -- Check if file exists, if not use the directory
  if vim.fn.filereadable(path) == 0 then
    path = vim.fn.expand('%:p:h')
    winpath = M.to_windows_path(path)
  end
  
  -- Execute the explorer.exe command with the Windows path
  local cmd = string.format('explorer.exe "%s"', winpath)
  vim.fn.system(cmd)
  
  vim.notify(string.format("Opening in Windows Explorer: %s", winpath), vim.log.levels.INFO)
end

-- Copy to Windows clipboard using clip.exe
M.copy_to_win_clipboard = function()
  local selection = vim.api.nvim_buf_get_visual_selection and 
                    vim.api.nvim_buf_get_visual_selection() or 
                    {vim.fn.getreg('""')}
  
  local text = table.concat(selection, "\n")
  local cmd = string.format('echo %s | clip.exe', vim.fn.shellescape(text))
  vim.fn.system(cmd)
  
  vim.notify("Copied to Windows clipboard", vim.log.levels.INFO)
end

-- Setup clipboard integration
M.setup_clipboard = function()
  if M.is_wsl() then
    vim.g.clipboard = {
      name = 'WslClipboard',
      copy = {
        ['+'] = 'clip.exe',
        ['*'] = 'clip.exe',
      },
      paste = {
        ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
      cache_enabled = 0,
    }
  end
end

-- Open the current file in VSCode
M.open_in_vscode = function()
  local path = vim.fn.expand('%:p')
  
  if vim.fn.filereadable(path) == 0 then
    vim.notify("No file to open in VSCode", vim.log.levels.ERROR)
    return
  end
  
  -- If it's a Windows path, use it directly, otherwise convert
  local cmd = string.format('code "%s"', path)
  vim.fn.system(cmd)
  
  vim.notify(string.format("Opening in VSCode: %s", path), vim.log.levels.INFO)
end

-- Helper to detect common directories for projects
M.find_windows_home = function()
  local candidates = {
    "/mnt/c/Users/" .. os.getenv("USER"),
    "/mnt/c/Users/" .. os.getenv("USERNAME"),
  }
  
  for _, path in ipairs(candidates) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  
  return "/mnt/c/Users"
end

-- Setup additional mappings specific to WSL
M.setup_mappings = function()
  if not M.is_wsl() then return end
  
  local map = vim.keymap.set
  
  -- Windows integration commands under <leader>w namespace
  map("n", "<leader>we", function() M.open_in_explorer() end, { desc = "Open in Windows Explorer" })
  map("n", "<leader>wc", function() M.copy_to_win_clipboard() end, { desc = "Copy to Windows clipboard" })
  map("n", "<leader>wv", function() M.open_in_vscode() end, { desc = "Open in VSCode" })
  
  -- Quick access to Windows home folder
  map("n", "<leader>fw", function()
    if pcall(require, "telescope") and pcall(require, "telescope.builtin") then
      require('telescope.builtin').find_files({
        prompt_title = "Windows Home",
        cwd = M.find_windows_home(),
      })
    else
      vim.cmd('cd ' .. M.find_windows_home())
      vim.notify("Telescope not found, changing directory instead", vim.log.levels.INFO)
    end
  end, { desc = "Browse Windows home" })
  
  -- Register with which-key if available
  if pcall(require, "which-key") then
    local wk = require("which-key")
    wk.register({
      ["<leader>w"] = { 
        name = "+window/WSL",
        e = "Open in Explorer",
        c = "Copy to Win clipboard",
        v = "Open in VSCode" 
      },
      ["<leader>fw"] = "Browse Windows home",
    })
  end
end

return M
