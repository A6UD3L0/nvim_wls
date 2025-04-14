-- Windows integration for WSL Neovim
-- Provides seamless access to Windows files and interoperability with Windows tools

local M = {}

-- Check if running in WSL
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

-- Copy to Windows clipboard
M.copy_to_win_clipboard = function()
  -- Check if visual selection or current line
  local text = ""
  local mode = vim.fn.mode()
  
  if mode == 'v' or mode == 'V' or mode == '' then
    -- Visual mode, get selection
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[2]-1, end_pos[2], false)
    
    -- Adjust first and last lines
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
    
    text = table.concat(lines, "\n")
  else
    -- Normal mode, get current line
    text = vim.fn.getline('.')
  end
  
  -- Use temporary file to avoid shell escaping issues
  local temp_file = os.tmpname()
  local file = io.open(temp_file, "w")
  if file then
    file:write(text)
    file:close()
    vim.fn.system(string.format('cat %s | clip.exe', temp_file))
    os.remove(temp_file)
    vim.notify("Copied to Windows clipboard", vim.log.levels.INFO)
  else
    vim.notify("Failed to create temporary file for clipboard", vim.log.levels.ERROR)
  end
end

-- Open in VSCode
M.open_in_vscode = function()
  local path = vim.fn.expand('%:p')
  
  if vim.fn.filereadable(path) == 0 then
    vim.notify("No file to open in VSCode", vim.log.levels.ERROR)
    return
  end
  
  local cmd = string.format('code "%s"', path)
  vim.fn.system(cmd)
  
  vim.notify(string.format("Opening in VSCode: %s", path), vim.log.levels.INFO)
end

-- Open PowerShell in current directory
M.open_powershell = function()
  local path = vim.fn.expand('%:p:h')
  local winpath = M.to_windows_path(path)
  
  local cmd = string.format('powershell.exe -NoExit -Command "cd %s"', winpath)
  vim.fn.system(cmd)
  
  vim.notify(string.format("Opening PowerShell in: %s", winpath), vim.log.levels.INFO)
end

-- Find and go to Windows home directory
M.find_windows_home = function()
  local candidates = {
    "/mnt/c/Users/" .. os.getenv("USER"),
    "/mnt/c/Users/" .. os.getenv("USERNAME"),
  }
  
  for _, path in ipairs(candidates) do
    if vim.fn.isdirectory(path) == 1 then
      vim.cmd('cd ' .. path)
      vim.notify("Changed to Windows home: " .. path, vim.log.levels.INFO)
      return path
    end
  end
  
  -- Fallback to general Users directory
  local fallback = "/mnt/c/Users"
  vim.cmd('cd ' .. fallback)
  vim.notify("Changed to Windows Users directory", vim.log.levels.INFO)
  return fallback
end

-- Setup all Windows integration mappings
M.setup = function()
  if not M.is_wsl() then return end
  
  local map = vim.keymap.set
  
  -- Windows integration mappings
  map("n", "<leader>wie", function() M.open_in_explorer() end, { desc = "Open in Windows Explorer" })
  map("n", "<leader>wic", function() M.copy_to_win_clipboard() end, { desc = "Copy to Windows clipboard" })
  map("v", "<leader>wic", function() M.copy_to_win_clipboard() end, { desc = "Copy selection to Windows clipboard" })
  map("n", "<leader>wiv", function() M.open_in_vscode() end, { desc = "Open in VSCode" })
  map("n", "<leader>wip", function() M.open_powershell() end, { desc = "Open in PowerShell" })
  map("n", "<leader>wiw", function() M.find_windows_home() end, { desc = "Go to Windows home" })
  
  -- Windows file explorer shortcut (to match overall UX pattern)
  map("n", "<leader>fw", function()
    if pcall(require, "telescope") and pcall(require, "telescope.builtin") then
      local win_home = M.find_windows_home()
      vim.cmd('cd ' .. win_home) -- Change directory first
      require('telescope.builtin').find_files({
        prompt_title = "Windows Files",
      })
    else
      M.find_windows_home() -- Fallback if telescope not available
    end
  end, { desc = "Browse Windows files" })
  
  vim.notify("Windows integration mappings loaded", vim.log.levels.INFO)
end

return M
