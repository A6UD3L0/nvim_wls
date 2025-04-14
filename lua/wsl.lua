-- WSL-specific utilities and helpers
local M = {}

-- Detect if running in WSL
M.is_wsl = function()
  local output = vim.fn.system('uname -r')
  return output:lower():match('microsoft') ~= nil or output:lower():match('wsl') ~= nil
end

-- Convert WSL path to Windows path with improved handling
M.to_windows_path = function(path)
  if not path then return nil end
  
  -- Standard /mnt/c/... path
  if path:match('^/mnt/([a-zA-Z])/(.*)$') then
    local drive, rest = path:match('^/mnt/([a-zA-Z])/(.*)')
    return drive:upper() .. ':\\' .. rest:gsub('/', '\\')
  end
  
  -- Special handling for ~ path
  if path:match('^~') then
    local expanded = vim.fn.expand(path)
    if expanded:match('^/home/') then
      -- Try to convert to Windows Users directory if that's where it should map
      local username = M.get_windows_username()
      if username and username ~= "" then
        local winhome = "/mnt/c/Users/" .. username
        local userhome = vim.fn.expand('~')
        if expanded:match('^' .. userhome) then
          return 'C:\\Users\\' .. username .. expanded:gsub('^' .. userhome, ''):gsub('/', '\\')
        end
      end
    end
    return expanded
  end
  
  -- Handle root-level WSL paths for improved compatibility
  if path:match('^/home/') then
    return path
  end
  
  return path
end

-- Convert Windows path to WSL path with improved handling
M.to_wsl_path = function(path)
  if not path then return nil end
  
  -- Standard C:\ style path
  if path:match('^([a-zA-Z]):(.*)$') then
    local drive, rest = path:match('^([a-zA-Z]):(.*)')
    return '/mnt/' .. drive:lower() .. rest:gsub('\\', '/')
  end
  
  -- UNC paths (\\server\share)
  if path:match('^\\\\') then
    return path:gsub('\\', '/')
  end
  
  return path
end

-- Get Windows username with fallback methods
M.get_windows_username = function()
  -- Try different methods to get Windows username
  local username = os.getenv("USERNAME")
  
  if not username or username == "" then
    -- Try WSL environment variable
    username = os.getenv("USER")
  end
  
  if not username or username == "" then
    -- Try to get it from the Windows home path
    local cmd = 'powershell.exe -c "[Environment]::UserName"'
    local handle = io.popen(cmd)
    if handle then
      local result = handle:read("*a")
      handle:close()
      username = result:gsub("[\r\n]", "")
    end
  end
  
  if not username or username == "" then
    -- Last resort, try parsing from the home path
    local home_path = vim.fn.expand('~')
    username = home_path:match('/home/([^/]+)')
  end
  
  return username or ""
end

-- Get Windows home directory
M.get_windows_home = function()
  local username = M.get_windows_username()
  if username and username ~= "" then
    return "/mnt/c/Users/" .. username
  end
  return "/mnt/c/Users"
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
  
  local joined = table.concat(selection, "\n")
  local cmd = string.format('echo %s | clip.exe', vim.fn.shellescape(joined))
  vim.fn.system(cmd)
  
  vim.notify("Copied to Windows clipboard", vim.log.levels.INFO)
end

-- Open current file in VSCode
M.open_in_vscode = function()
  local path = vim.fn.expand('%:p')
  local winpath = M.to_windows_path(path)
  
  -- Execute the code command with the Windows path
  local cmd = string.format('code.exe "%s"', winpath)
  vim.fn.system(cmd)
  
  vim.notify(string.format("Opening in VSCode: %s", winpath), vim.log.levels.INFO)
end

-- Open PowerShell in current directory
M.open_powershell = function()
  local path = vim.fn.expand('%:p:h')
  local winpath = M.to_windows_path(path)
  
  -- Execute powershell.exe in the Windows path
  local cmd = string.format('powershell.exe -NoExit -Command "cd \'%s\'"', winpath)
  vim.fn.system(cmd)
  
  vim.notify(string.format("Opening PowerShell in: %s", winpath), vim.log.levels.INFO)
end

-- Go to Windows user home directory
M.goto_windows_home = function()
  local win_home = M.get_windows_home()
  
  if vim.fn.isdirectory(win_home) == 1 then
    vim.cmd('cd ' .. win_home)
    vim.notify("Changed to Windows home directory: " .. win_home, vim.log.levels.INFO)
  else
    vim.notify("Windows home directory not found: " .. win_home, vim.log.levels.ERROR)
  end
end

-- Navigate to Windows documents folder
M.goto_windows_documents = function()
  local win_home = M.get_windows_home()
  local documents = win_home .. "/Documents"
  
  if vim.fn.isdirectory(documents) == 1 then
    vim.cmd('cd ' .. documents)
    vim.notify("Changed to Windows Documents: " .. documents, vim.log.levels.INFO)
  else
    vim.notify("Windows Documents directory not found: " .. documents, vim.log.levels.ERROR)
  end
end

-- Navigate to Windows desktop folder
M.goto_windows_desktop = function()
  local win_home = M.get_windows_home()
  local desktop = win_home .. "/Desktop"
  
  if vim.fn.isdirectory(desktop) == 1 then
    vim.cmd('cd ' .. desktop)
    vim.notify("Changed to Windows Desktop: " .. desktop, vim.log.levels.INFO)
  else
    vim.notify("Windows Desktop directory not found: " .. desktop, vim.log.levels.ERROR)
  end
end

-- Browse Windows files with Telescope
M.browse_windows_files = function()
  if pcall(require, "telescope") and pcall(require, "telescope.builtin") then
    require('telescope.builtin').find_files({
      prompt_title = "Windows Files",
      cwd = M.get_windows_home(),
    })
  else
    vim.notify("Telescope not found, changing directory instead", vim.log.levels.INFO)
    M.goto_windows_home()
  end
end

-- Browse Windows Desktop files with Telescope
M.browse_windows_desktop = function()
  if pcall(require, "telescope") and pcall(require, "telescope.builtin") then
    local win_home = M.get_windows_home()
    local desktop = win_home .. "/Desktop"
    
    if vim.fn.isdirectory(desktop) == 1 then
      require('telescope.builtin').find_files({
        prompt_title = "Windows Desktop Files",
        cwd = desktop,
      })
    else
      vim.notify("Windows Desktop directory not found, browsing home instead", vim.log.levels.WARN)
      M.browse_windows_files()
    end
  else
    vim.notify("Telescope not found, changing directory instead", vim.log.levels.INFO)
    M.goto_windows_desktop()
  end
end

-- Fix file paths when opening files
M.fix_path = function(file_path)
  if not file_path then return nil end
  if vim.fn.filereadable(file_path) == 1 then
    return file_path
  end
  
  -- Try to convert Windows path to WSL
  if file_path:match('^([a-zA-Z]):(.*)$') then
    local wsl_path = M.to_wsl_path(file_path)
    if vim.fn.filereadable(wsl_path) == 1 then
      return wsl_path
    end
  end
  
  -- Try to convert WSL path to Windows
  if file_path:match('^/mnt/([a-zA-Z])/(.*)$') then
    local win_path = M.to_windows_path(file_path)
    if vim.fn.filereadable(win_path) == 1 then
      return win_path
    end
  end
  
  return file_path
end

-- Set up WSL-specific mappings
M.setup = function()
  if not M.is_wsl() then
    vim.notify("Not running in WSL, Windows integration disabled", vim.log.levels.INFO)
    return
  end
  
  vim.notify("WSL detected - Windows integration enabled", vim.log.levels.INFO)
  
  -- Set up file path correction for editing commands
  vim.api.nvim_create_autocmd("BufNewFile", {
    pattern = "*",
    callback = function(ev)
      local fixed_path = M.fix_path(ev.file)
      if fixed_path and fixed_path ~= ev.file then
        vim.cmd("edit " .. fixed_path)
        return true
      end
    end,
  })
  
  -- Improve netrw to work with Windows paths when browsing
  vim.g.netrw_cygwin = 0
  vim.g.netrw_scp_cmd = "scp -q"
  
  -- Register with which-key if available
  if pcall(require, "which-key") then
    local wk = require("which-key")
    
    wk.register({
      w = {
        name = "Windows",
        e = { M.open_in_explorer, "Open in Explorer" },
        c = { M.copy_to_win_clipboard, "Copy to Windows clipboard" },
        v = { M.open_in_vscode, "Open in VSCode" },
        p = { M.open_powershell, "Open PowerShell here" },
        h = { M.goto_windows_home, "Go to Windows home" },
        d = { M.goto_windows_documents, "Go to Windows Documents" },
        k = { M.goto_windows_desktop, "Go to Windows Desktop" },
        f = { M.browse_windows_files, "Find Windows files" },
        b = { M.browse_windows_desktop, "Browse Windows Desktop" },
      }
    }, { prefix = "<leader>" })
  else
    -- Set up basic key mappings if which-key is not available
    vim.keymap.set("n", "<leader>we", M.open_in_explorer, { desc = "Open in Explorer" })
    vim.keymap.set("n", "<leader>wc", M.copy_to_win_clipboard, { desc = "Copy to Windows clipboard" })
    vim.keymap.set("n", "<leader>wv", M.open_in_vscode, { desc = "Open in VSCode" })
    vim.keymap.set("n", "<leader>wp", M.open_powershell, { desc = "Open PowerShell here" })
    vim.keymap.set("n", "<leader>wh", M.goto_windows_home, { desc = "Go to Windows home" })
    vim.keymap.set("n", "<leader>wd", M.goto_windows_documents, { desc = "Go to Windows Documents" })
    vim.keymap.set("n", "<leader>wk", M.goto_windows_desktop, { desc = "Go to Windows Desktop" })
    vim.keymap.set("n", "<leader>wf", M.browse_windows_files, { desc = "Find Windows files" })
    vim.keymap.set("n", "<leader>wb", M.browse_windows_desktop, { desc = "Browse Windows Desktop" })
  end
  
  -- Hook into Telescope if available to enhance Windows file browsing
  if pcall(require, "telescope") then
    local telescope = require("telescope")
    -- Add Windows path handling to Telescope
    telescope.setup({
      defaults = {
        file_sorter = require("telescope.sorters").get_fzy_sorter,
        path_display = { "truncate" },
      },
      extensions = {
        -- Add Windows-friendly path display
        path_display = function(_, path)
          local rel_path = require("plenary.path"):new(path):make_relative(vim.fn.getcwd())
          return rel_path
        end,
      },
    })
  end
end

return M
