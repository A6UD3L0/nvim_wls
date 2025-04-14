-- Seamless Neovim keybindings for backend development
-- Combines ThePrimeagen's mappings with NvChad simplicity
-- WSL-optimized version with Windows interoperability

-- Set leader key to space
vim.g.mapleader = " "

-- Detect WSL environment
local is_wsl = (function()
  local output = vim.fn.system('uname -r')
  return output:lower():match('microsoft') ~= nil or output:lower():match('wsl') ~= nil
end)()

-- Create a local mapping function to use whether or not which-key is available
local map = vim.keymap.set

-- Create a module for exported functions
local M = {}

-- Helper for checking if a command exists
M._command_exists = function(cmd)
  local handle = io.popen("which " .. cmd .. " 2>/dev/null")
  if not handle then return false end
  
  local result = handle:read("*a")
  handle:close()
  
  return result and #result > 0
end

-- Generic plugin availability check function
M._has_plugin = function(plugin_name)
  local status_ok, _ = pcall(require, plugin_name)
  return status_ok
end

-- Helper to run a command in a toggleterm window
M._run_in_terminal = function(cmd, direction)
  direction = direction or "horizontal"
  
  -- Check that toggleterm is available
  local toggleterm_ok, toggleterm = pcall(require, "toggleterm.terminal")
  if not toggleterm_ok then
    vim.notify("ToggleTerm plugin not found. Please install akinsho/toggleterm.nvim", vim.log.levels.ERROR)
    return
  end
  
  local term = toggleterm.Terminal:new({
    cmd = cmd,
    direction = direction,
    close_on_exit = false,
  })
  term:toggle()
end

-- IPython terminal toggle implementation
M._toggle_ipython = function()
  -- Check if ipython is installed
  if not M._command_exists("ipython") then
    vim.notify("IPython is not installed. Please install it first.", vim.log.levels.ERROR)
    return
  end
  
  local venv_path = vim.fn.finddir(".venv", vim.fn.getcwd() .. ";")
  local cmd = ""
  
  if venv_path ~= "" then
    cmd = "source " .. venv_path .. "/bin/activate && ipython"
  elseif vim.fn.filereadable(".python-version") == 1 then
    cmd = "pyenv shell $(cat .python-version) && ipython"  
  else
    cmd = "ipython"
  end
  
  M._run_in_terminal(cmd)
end

-- Docker terminal implementation
M._toggle_docker_terminal = function()
  -- Check if docker is installed
  if not M._command_exists("docker") then
    vim.notify("Docker is not installed. Please install it first.", vim.log.levels.ERROR)
    return
  end
  
  M._run_in_terminal("docker ps")
end

-- Database terminal implementation
M._toggle_database_terminal = function()
  -- Try to determine which database tools are available
  local db_clients = {
    { cmd = "psql", name = "PostgreSQL" },
    { cmd = "mysql", name = "MySQL" },
    { cmd = "sqlite3", name = "SQLite" },
    { cmd = "mongosh", name = "MongoDB" },
  }
  
  local available_clients = {}
  for _, client in ipairs(db_clients) do
    if M._command_exists(client.cmd) then
      table.insert(available_clients, client)
    end
  end
  
  if #available_clients == 0 then
    vim.notify("No database clients found. Please install a database client.", vim.log.levels.ERROR)
    return
  elseif #available_clients == 1 then
    -- Only one client available, use it directly
    local client = available_clients[1]
    vim.notify("Opening " .. client.name .. " terminal", vim.log.levels.INFO)
    M._run_in_terminal(client.cmd)
  else
    -- Multiple clients available, let user choose
    local choices = {}
    for _, client in ipairs(available_clients) do
      table.insert(choices, client.name)
    end
    
    vim.ui.select(choices, {
      prompt = "Select database client:",
    }, function(choice)
      if not choice then return end
      
      for _, client in ipairs(available_clients) do
        if client.name == choice then
          M._run_in_terminal(client.cmd)
          break
        end
      end
    end)
  end
end

-- Python venv smart activation
M._venv_smart_activate = function()
  -- Check if venv_diagnostics module is available
  if _G.VenvDiagnostics and _G.VenvDiagnostics.smart_activate then
    _G.VenvDiagnostics.smart_activate()
    return true
  end
  
  -- Fallback implementation
  local venv_path = vim.fn.finddir(".venv", vim.fn.getcwd() .. ";")
  local pyenv_path = vim.fn.finddir(".python-version", vim.fn.getcwd() .. ";")
  local poetry_path = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
  
  if venv_path ~= "" then
    vim.notify("Detected .venv directory", vim.log.levels.INFO)
    return true
  elseif pyenv_path ~= "" then
    vim.notify("Detected .python-version file", vim.log.levels.INFO)
    return true
  elseif poetry_path ~= "" then
    vim.notify("Detected poetry project", vim.log.levels.INFO)
    return true
  else
    vim.notify("No Python environment detected", vim.log.levels.WARN)
    return false
  end
end

-- Run Python file with environment
M._python_run_file = function()
  local file = vim.fn.expand('%:p')
  if vim.fn.filereadable(file) == 0 then
    vim.notify("No file to run", vim.log.levels.ERROR)
    return
  end
  
  if vim.bo.filetype ~= "python" then
    vim.notify("Not a Python file", vim.log.levels.ERROR)
    return
  end
  
  -- Call VenvDiagnostics.run_with_env if available
  if _G.VenvDiagnostics and _G.VenvDiagnostics.run_with_env then
    _G.VenvDiagnostics.run_with_env()
    return
  end
  
  -- Fallback implementation
  local venv_path = vim.fn.finddir(".venv", vim.fn.getcwd() .. ";")
  local pyenv_path = vim.fn.finddir(".python-version", vim.fn.getcwd() .. ";")
  local poetry_path = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
  local python_cmd = "python"
  
  if venv_path ~= "" then
    python_cmd = "source " .. venv_path .. "/bin/activate && python"
  elseif pyenv_path ~= "" then
    python_cmd = "pyenv shell $(cat " .. pyenv_path .. ") && python"
  elseif poetry_path ~= "" then
    python_cmd = "poetry run python"
  end
  
  M._run_in_terminal(python_cmd .. " \"" .. file .. "\"")
end

-- Execute Python snippet (selected text)
M._python_execute_snippet = function()
  -- Get visual selection
  local lines = vim.api.nvim_buf_get_visual_selection()
  
  -- Create a temporary file
  local temp_file = os.tmpname() .. ".py"
  local f = io.open(temp_file, "w")
  if not f then
    vim.notify("Failed to create temporary file", vim.log.levels.ERROR)
    return
  end
  
  -- Write the selection to the file
  for _, line in ipairs(lines) do
    f:write(line .. "\n")
  end
  f:close()
  
  -- Run the file
  M._run_in_terminal("python " .. temp_file)
end

-- Run current selection in IPython
M._python_execute_in_ipython = function()
  -- Get visual selection
  local lines = vim.api.nvim_buf_get_visual_selection()
  local code = table.concat(lines, "\n")
  
  -- Escape any quotes
  code = code:gsub('"', '\\"')
  
  -- Run in IPython
  M._run_in_terminal('ipython -c "' .. code .. '"')
end

-- Create a new Python file
M._python_new_file = function()
  vim.ui.input({ prompt = "Enter filename: " }, function(name)
    if not name or name == "" then return end
    
    -- Add .py extension if not present
    if not name:match("%.py$") then
      name = name .. ".py"
    end
    
    -- Open the file
    vim.cmd("e " .. name)
    
    -- Add a basic header
    local lines = {
      "#!/usr/bin/env python3",
      "# -*- coding: utf-8 -*-",
      '"""',
      name .. " - [Brief description]",
      "",
      "Created on " .. os.date("%Y-%m-%d"),
      '"""',
      "",
      "",
      "def main():",
      "    pass",
      "",
      "",
      'if __name__ == "__main__":',
      "    main()",
      "",
    }
    
    vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
    -- Position cursor at a sensible position (line 11, column 5)
    vim.api.nvim_win_set_cursor(0, {11, 4})
  end)
end

-- POETRY FUNCTIONS

-- Check if Poetry is installed
M._check_poetry = function()
  local poetry_installed = M._command_exists("poetry")
  if not poetry_installed then
    vim.notify("Poetry is not installed. Please install it first.", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Poetry shell
M._poetry_shell = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry shell")
end

-- Create Poetry environment and install dependencies
M._poetry_create_venv = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry install")
end

-- Add a package with Poetry
M._poetry_add_package = function()
  if not M._check_poetry() then return end
  
  vim.ui.input({ prompt = "Package to add: " }, function(package)
    if not package or package == "" then return end
    
    -- Ask if it's a dev dependency
    vim.ui.select({ "regular", "dev" }, {
      prompt = "Dependency type:",
    }, function(choice)
      if not choice then return end
      
      local cmd = "poetry add " .. package
      if choice == "dev" then
        cmd = cmd .. " --group dev"
      end
      
      M._run_in_terminal(cmd)
    end)
  end)
end

-- Remove a package with Poetry
M._poetry_remove_package = function()
  if not M._check_poetry() then return end
  
  -- Get list of installed packages
  local handle = io.popen("poetry show --no-ansi | awk '{print $1}'")
  if not handle then
    vim.notify("Failed to get package list", vim.log.levels.ERROR)
    return
  end
  
  local packages = {}
  for line in handle:lines() do
    table.insert(packages, line)
  end
  handle:close()
  
  if #packages == 0 then
    vim.notify("No packages installed", vim.log.levels.INFO)
    return
  end
  
  -- Select package to remove
  vim.ui.select(packages, {
    prompt = "Select package to remove:",
  }, function(package)
    if not package then return end
    
    M._run_in_terminal("poetry remove " .. package)
  end)
end

-- Update packages with Poetry
M._poetry_update = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry update")
end

-- Show outdated packages
M._poetry_show_outdated = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry show --outdated")
end

-- Generate requirements.txt from Poetry
M._poetry_generate_requirements = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry export --format requirements.txt --output requirements.txt --without-hashes")
end

-- Create a new Poetry project
M._poetry_new = function()
  if not M._check_poetry() then return end
  
  vim.ui.input({ prompt = "Project name: " }, function(name)
    if not name or name == "" then return end
    M._run_in_terminal("poetry new " .. name)
    
    -- Ask if user wants to cd into the project
    vim.ui.select({ "Yes", "No" }, {
      prompt = "Change to project directory?",
    }, function(choice)
      if choice == "Yes" then
        vim.cmd("cd " .. name)
        vim.notify("Changed to directory: " .. name, vim.log.levels.INFO)
      end
    end)
  end)
end

-- Build Poetry package
M._poetry_build = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry build")
end

-- Publish Poetry package
M._poetry_publish = function()
  if not M._check_poetry() then return end
  M._run_in_terminal("poetry publish")
end

-- Edit pyproject.toml
M._poetry_edit_pyproject = function()
  local path = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
  if path == "" then
    vim.notify("pyproject.toml not found", vim.log.levels.ERROR)
    return
  end
  
  vim.cmd("edit " .. path)
end

-- Run a command with Poetry
M._poetry_run = function()
  if not M._check_poetry() then return end
  
  vim.ui.input({ prompt = "Command to run: " }, function(cmd)
    if not cmd or cmd == "" then return end
    M._run_in_terminal("poetry run " .. cmd)
  end)
end

-- Documentation functions
M._toggle_documentation = function()
  -- Check if DevDocs is available
  local devdocs_ok, _ = pcall(require, "nvim-devdocs")
  if not devdocs_ok then
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
    return
  end
  
  -- Check if a buffer with DevDocs is already open
  local found = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match("DevDocs") or buf_name:match("devdocs://") then
        -- Find windows containing this buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == buf then
            vim.api.nvim_set_current_win(win)
            found = true
            break
          end
        end
        
        if found then
          -- If found but not visible in a window, close it - this effectively toggles
          vim.cmd("close")
          return
        end
      end
    end
  end
  
  -- If not found or not visible, open new documentation
  local ft = vim.bo.filetype
  if ft == "" then
    -- No filetype, just open general docs
    vim.cmd("DevdocsOpenFloat")
    return
  end
  
  -- Map filetypes to their documentation types
  local ft_map = {
    python = "python~3.11",  -- Use specific Python version
    javascript = "javascript",
    typescript = "typescript",
    go = "go",
    rust = "rust",
    lua = "lua",
    c = "c",
    cpp = "cpp",
    bash = "bash",
    sh = "bash",
    html = "html",
    css = "css",
    markdown = "markdown",
    sql = "sql",
    postgresql = "postgresql",
    docker = "docker",
    json = "json",
    yaml = "yaml",
    toml = "toml",
  }
  
  -- Additional documentation mapping for specialized topics
  local specialized_docs = {
    ["sklearn"] = "scikit_learn",
    ["scikit-learn"] = "scikit_learn",
    ["ml"] = "scikit_learn",
    ["machinelearning"] = "scikit_learn",
    ["numpy"] = "numpy~1.24",
    ["pandas"] = "pandas~1",
    ["tensorflow"] = "tensorflow~2.12",
    ["pytorch"] = "pytorch",
  }
  
  local doc_type = ft_map[ft] or specialized_docs[ft] or ft
  
  -- Try to open documentation for the specific filetype
  local success = pcall(vim.cmd, "DevdocsOpenFloat " .. vim.fn.shellescape(doc_type))
  
  -- If it fails, try to install the documentation
  if not success then
    vim.notify("Documentation for " .. doc_type .. " not found. Attempting to install...", vim.log.levels.INFO)
    vim.cmd("DevdocsFetch")
    vim.defer_fn(function()
      pcall(vim.cmd, "DevdocsInstall " .. vim.fn.shellescape(doc_type))
      vim.defer_fn(function()
        pcall(vim.cmd, "DevdocsOpenFloat " .. vim.fn.shellescape(doc_type))
      end, 2000)
    end, 1000)
  end
end

-- Documentation keybinding
map("n", "<leader>do", function() M._toggle_documentation() end, { desc = "Toggle documentation" })

-- Add specialized documentation commands for machine learning
M._open_ml_docs = function(doc_type)
  -- Check if DevDocs is available
  local devdocs_ok, _ = pcall(require, "nvim-devdocs")
  if not devdocs_ok then
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
    return
  end
  
  -- Map shorthand names to full documentation IDs
  local ml_docs = {
    ["sklearn"] = "scikit_learn",
    ["scikit-learn"] = "scikit_learn",
    ["numpy"] = "numpy~1.24",
    ["pandas"] = "pandas~1",
    ["tf"] = "tensorflow~2.12",
    ["tensorflow"] = "tensorflow~2.12",
    ["pytorch"] = "pytorch",
    ["matplotlib"] = "matplotlib~3",
    ["ml"] = "scikit_learn",  -- Default to scikit-learn for generic ML request
  }
  
  local target_doc = ml_docs[doc_type] or doc_type
  
  -- Try to open documentation
  local success = pcall(vim.cmd, "DevdocsOpenFloat " .. vim.fn.shellescape(target_doc))
  
  -- If failed, try to install the documentation
  if not success then
    vim.notify("Documentation for " .. target_doc .. " not found. Attempting to install...", vim.log.levels.INFO)
    vim.cmd("DevdocsFetch")
    vim.defer_fn(function()
      pcall(vim.cmd, "DevdocsInstall " .. vim.fn.shellescape(target_doc))
      vim.defer_fn(function()
        pcall(vim.cmd, "DevdocsOpenFloat " .. vim.fn.shellescape(target_doc))
      end, 2000)
    end, 1000)
  end
end

-- Machine learning documentation keybindings
map("n", "<leader>dm", function() 
  vim.ui.select(
    { "sklearn", "numpy", "pandas", "tensorflow", "pytorch", "matplotlib" },
    { prompt = "Select ML Documentation:" },
    function(choice) 
      if choice then M._open_ml_docs(choice) end
    end
  )
end, { desc = "Browse ML documentation" })

-- =============================================
-- TERMINAL OPERATIONS (t namespace)
-- =============================================

-- Smart Terminal - automatically uses local virtual environment if available
M._smart_terminal = function()
  -- Check that toggleterm is available
  local toggleterm_ok, toggleterm = pcall(require, "toggleterm.terminal")
  if not toggleterm_ok then
    vim.notify("ToggleTerm plugin not found. Please install akinsho/toggleterm.nvim", vim.log.levels.ERROR)
    return
  end

  local venv_path = vim.fn.finddir(".venv", vim.fn.getcwd() .. ";")
  local cmd = ""
  
  if venv_path ~= "" then
    cmd = "source " .. venv_path .. "/bin/activate && clear"
    vim.notify("Terminal using .venv environment", vim.log.levels.INFO)
  elseif vim.fn.filereadable(".python-version") == 1 then
    cmd = "pyenv shell $(cat .python-version) && clear"
    vim.notify("Terminal using pyenv environment", vim.log.levels.INFO)
  else
    cmd = "clear"
  end
  
  local term = toggleterm.Terminal:new({
    cmd = cmd,
    direction = "horizontal",
    close_on_exit = false,
  })
  term:toggle()
end

-- Generic terminal toggle (from ToggleTerm plugin)
map("n", "<leader>tt", function()
  -- Check that toggleterm is available
  local toggleterm_ok, _ = pcall(require, "toggleterm")
  if not toggleterm_ok then
    vim.notify("ToggleTerm plugin not found. Please install akinsho/toggleterm.nvim", vim.log.levels.ERROR)
    return
  end
  vim.cmd("ToggleTerm direction=horizontal")
end, { desc = "Toggle horizontal terminal" })

map("n", "<leader>tf", function()
  -- Check that toggleterm is available
  local toggleterm_ok, _ = pcall(require, "toggleterm")
  if not toggleterm_ok then
    vim.notify("ToggleTerm plugin not found. Please install akinsho/toggleterm.nvim", vim.log.levels.ERROR)
    return
  end
  vim.cmd("ToggleTerm direction=float")
end, { desc = "Toggle floating terminal" })

map("n", "<leader>tv", function()
  -- Check that toggleterm is available
  local toggleterm_ok, _ = pcall(require, "toggleterm")
  if not toggleterm_ok then
    vim.notify("ToggleTerm plugin not found. Please install akinsho/toggleterm.nvim", vim.log.levels.ERROR)
    return
  end
  vim.cmd("ToggleTerm direction=vertical")
end, { desc = "Toggle vertical terminal" })

map("n", "<leader>ts", function() M._smart_terminal() end, { desc = "Smart terminal (with venv)" })

-- Python terminal instances
map("n", "<leader>tp", function() 
  -- Check that python is available
  if not M._command_exists("python") then
    vim.notify("Python is not installed or not in PATH", vim.log.levels.ERROR)
    return
  end

  -- Check that toggleterm is available
  local toggleterm_ok, toggleterm = pcall(require, "toggleterm.terminal")
  if not toggleterm_ok then
    vim.notify("ToggleTerm plugin not found. Please install akinsho/toggleterm.nvim", vim.log.levels.ERROR)
    return
  end

  M._venv_smart_activate()
  vim.defer_fn(function() 
    local term = toggleterm.Terminal:new({
      cmd = "python",
      direction = "horizontal",
      close_on_exit = false,
    })
    term:toggle()
  end, 500)
end, { desc = "Python Terminal" })

-- IPython terminal
map("n", "<leader>ti", function() M._toggle_ipython() end, { desc = "IPython Terminal" })

-- Run current Python file
map("n", "<leader>tr", function() M._python_run_file() end, { desc = "Run current Python file" })

-- Docker terminal
map("n", "<leader>td", function() M._toggle_docker_terminal() end, { desc = "Docker Terminal" })

-- Database terminal
map("n", "<leader>tb", function() M._toggle_database_terminal() end, { desc = "Database Terminal" })

-- Terminal mode mappings
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode with jk" })

-- Exit insert mode with jk (MECE, does not interfere with terminal mode mapping)
map("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })

-- =============================================
-- BUFFER OPERATIONS (b namespace)
-- =============================================

-- Buffer management
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bl", "<cmd>buffers<CR>", { desc = "List buffers" })

-- =============================================
-- FILE EXPLORER OPERATIONS (e namespace)
-- =============================================

-- Check if NvimTree is available
M._has_nvim_tree = function()
  if not M._has_plugin("nvim-tree") then
    vim.notify("NvimTree plugin not found. Please install nvim-tree/nvim-tree.lua", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- File explorer mappings
map("n", "<leader>e", function()
  if M._has_nvim_tree() then
    vim.cmd("NvimTreeToggle")
  end
end, { desc = "Toggle file explorer" })

map("n", "<leader>ef", function()
  if M._has_nvim_tree() then
    vim.cmd("NvimTreeFocus")
  end
end, { desc = "Focus file explorer" })

-- Quick access to built-in file explorer (complements NvimTree)
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open Netrw file explorer" })

-- =============================================
-- FILE/FIND OPERATIONS (f namespace)
-- =============================================

-- Check if Telescope is available
M._has_telescope = function()
  if not M._has_plugin("telescope") then
    vim.notify("Telescope plugin not found. Please install nvim-telescope/telescope.nvim", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Telescope/find mappings
map("n", "<leader>ff", function()
  if M._has_telescope() then
    vim.cmd("Telescope find_files")
  end
end, { desc = "Find files" })

map("n", "<leader>fg", function()
  if M._has_telescope() then
    vim.cmd("Telescope live_grep")
  end
end, { desc = "Find in files (grep)" })

map("n", "<leader>fb", function()
  if M._has_telescope() then
    vim.cmd("Telescope buffers")
  end
end, { desc = "Find buffers" })

map("n", "<leader>fh", function()
  if M._has_telescope() then
    vim.cmd("Telescope help_tags")
  end
end, { desc = "Find help tags" })

map("n", "<leader>fr", function()
  if M._has_telescope() then
    vim.cmd("Telescope oldfiles")
  end
end, { desc = "Recent files" })

map("n", "<leader>fm", function()
  if M._has_telescope() then
    vim.cmd("Telescope marks")
  end
end, { desc = "Find marks" })

map("n", "<leader>fd", function()
  if M._has_plugin("dashboard") then
    require('dashboard').find_directory_and_cd()
  else
    vim.notify("Dashboard plugin not found", vim.log.levels.ERROR)
  end
end, { desc = "Find directory and cd" })

map("n", "<leader>fp", function()
  if M._has_telescope() and M._has_plugin("telescope") and pcall(require, "telescope").extensions.projects then
    vim.cmd("Telescope projects")
  else
    vim.notify("Telescope projects extension not available", vim.log.levels.ERROR)
  end
end, { desc = "Find projects" })

map("n", "<leader>fc", function()
  if M._has_telescope() then
    vim.cmd("Telescope commands")
  end
end, { desc = "Find commands" })

map("n", "<leader>f/", function()
  if M._has_telescope() then
    vim.cmd("Telescope current_buffer_fuzzy_find")
  end
end, { desc = "Find in current buffer" })

map("n", "<leader>fs", function()
  if M._has_telescope() then
    vim.cmd("Telescope lsp_document_symbols")
  end
end, { desc = "Find document symbols" })

map("n", "<leader>fz", function()
  if M._has_telescope() then
    vim.cmd("Telescope lsp_dynamic_workspace_symbols")
  end
end, { desc = "Find workspace symbols" })

-- File operations
map("n", "<leader>fw", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<leader>fW", "<cmd>wa<CR>", { desc = "Save all files" })
map("n", "<leader>fn", "<cmd>enew<CR>", { desc = "New file" })

-- =============================================
-- WINDOW OPERATIONS (w namespace)
-- =============================================

-- Window management
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "Split vertically" })
map("n", "<leader>wh", "<cmd>split<CR>", { desc = "Split horizontally" })
map("n", "<leader>we", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close current split" })
map("n", "<leader>wq", "<cmd>q<CR>", { desc = "Quit window" })
map("n", "<leader>wQ", "<cmd>qa<CR>", { desc = "Quit all windows" })
map("n", "<leader>wL", "<cmd>vertical resize +10<CR>", { desc = "Increase width" })
map("n", "<leader>wH", "<cmd>vertical resize -10<CR>", { desc = "Decrease width" })
map("n", "<leader>wK", "<cmd>resize +5<CR>", { desc = "Increase height" })
map("n", "<leader>wJ", "<cmd>resize -5<CR>", { desc = "Decrease height" })

-- Window navigation (without leader key for frequent operations)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to window below" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to window above" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Additional window navigation with leader key
map("n", "<leader>ww", "<C-w>w", { desc = "Cycle through windows" })
map("n", "<leader>wp", "<C-w>p", { desc = "Go to previous window" })
map("n", "<leader>wo", "<cmd>only<CR>", { desc = "Close all other windows" })
map("n", "<leader>wt", "<C-w>T", { desc = "Move window to new tab" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize window sizes" })
map("n", "<leader>ws", "<cmd>split<CR>", { desc = "Split window horizontally" })
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "Split window vertically" })

-- Tab management
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>to", "<cmd>tabonly<CR>", { desc = "Close all other tabs" })
map("n", "<leader>tl", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>th", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- =============================================
-- UNDOTREE OPERATION (u namespace)
-- =============================================

-- Check if Undotree is available
M._has_undotree = function()
  if vim.fn.exists(':UndotreeToggle') ~= 2 then
    vim.notify("Undotree plugin not found. Please install mbbill/undotree", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Undotree toggle
map("n", "<leader>u", function()
  if M._has_undotree() then
    vim.cmd("UndotreeToggle")
  end
end, { desc = "Toggle Undotree" })

-- =============================================
-- DOCUMENTATION (d namespace)
-- =============================================

-- Documentation operations
map("n", "<leader>do", function() M._toggle_documentation() end, { desc = "Toggle documentation" })

map("n", "<leader>dO", function()
  if M._has_plugin("nvim-devdocs") then
    vim.cmd("DevdocsOpen")
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Open documentation in buffer" })

map("n", "<leader>df", function()
  if M._has_plugin("nvim-devdocs") then
    vim.cmd("DevdocsFetch")
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Fetch documentation index" })

map("n", "<leader>di", function()
  if M._has_plugin("nvim-devdocs") then
    vim.cmd("DevdocsInstall")
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Install documentation" })

map("n", "<leader>du", function()
  if M._has_plugin("nvim-devdocs") then
    vim.cmd("DevdocsUpdate")
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Update documentation" })

map("n", "<leader>dU", function()
  if M._has_plugin("nvim-devdocs") then
    vim.cmd("DevdocsUpdateAll")
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Update all documentation" })

map("n", "<leader>dh", function()
  if M._has_plugin("nvim-devdocs") then
    vim.cmd("DevdocsSearch")
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Search in documentation" })

-- Machine learning documentation (d + m subfolder)
map("n", "<leader>dm", function()
  if not M._has_plugin("nvim-devdocs") then
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
    return
  end
  
  vim.ui.select(
    { "sklearn", "numpy", "pandas", "tensorflow", "pytorch", "matplotlib" },
    { prompt = "Select ML Documentation:" },
    function(choice) 
      if choice then M._open_ml_docs(choice) end
    end
  )
end, { desc = "Browse ML documentation" })

-- Specific ML docs shortcuts with proper error checking
map("n", "<leader>dmn", function() 
  if M._has_plugin("nvim-devdocs") then 
    M._open_ml_docs("numpy") 
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "NumPy docs" })

map("n", "<leader>dmp", function() 
  if M._has_plugin("nvim-devdocs") then 
    M._open_ml_docs("pandas") 
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Pandas docs" })

map("n", "<leader>dmt", function() 
  if M._has_plugin("nvim-devdocs") then 
    M._open_ml_docs("tensorflow") 
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "TensorFlow docs" })

map("n", "<leader>dmy", function() 
  if M._has_plugin("nvim-devdocs") then 
    M._open_ml_docs("pytorch") 
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "PyTorch docs" })

map("n", "<leader>dmm", function() 
  if M._has_plugin("nvim-devdocs") then 
    M._open_ml_docs("matplotlib") 
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Matplotlib docs" })

map("n", "<leader>dmk", function() 
  if M._has_plugin("nvim-devdocs") then 
    M._open_ml_docs("scikit-learn") 
  else
    vim.notify("DevDocs plugin not found. Please install luckasRanarison/nvim-devdocs", vim.log.levels.ERROR)
  end
end, { desc = "Scikit-learn docs" })

-- =============================================
-- POETRY OPERATIONS (o namespace)
-- =============================================

-- Poetry keybindings
map("n", "<leader>oi", function() M._poetry_create_venv() end, { desc = "Poetry install dependencies" })
map("n", "<leader>oc", function() M._poetry_new() end, { desc = "Create new Poetry project" })
map("n", "<leader>oa", function() M._poetry_add_package() end, { desc = "Add package" })
map("n", "<leader>or", function() M._poetry_remove_package() end, { desc = "Remove package" })
map("n", "<leader>ou", function() M._poetry_update() end, { desc = "Update packages" })
map("n", "<leader>oo", function() M._poetry_show_outdated() end, { desc = "Show outdated" })
map("n", "<leader>og", function() M._poetry_generate_requirements() end, { desc = "Generate requirements.txt" })
map("n", "<leader>ob", function() M._poetry_build() end, { desc = "Build package" })
map("n", "<leader>op", function() M._poetry_publish() end, { desc = "Publish package" })
map("n", "<leader>os", function() M._poetry_shell() end, { desc = "Poetry shell" })
map("n", "<leader>oe", function() M._poetry_edit_pyproject() end, { desc = "Edit pyproject.toml" })
map("n", "<leader>oR", function() M._poetry_run() end, { desc = "Poetry run command" })

-- =============================================
-- REQUIREMENTS MANAGEMENT (r namespace)
-- =============================================

-- Requirements management with Poetry integration
map("n", "<leader>rg", function() M._poetry_generate_requirements() end, { desc = "Generate from Poetry (recommended)" })
map("n", "<leader>re", "<cmd>edit requirements.txt<CR>", { desc = "Edit requirements.txt" })

map("n", "<leader>ri", function()
  if M._has_plugin("toggleterm") then
    vim.cmd("TermExec cmd='pip install -r requirements.txt'")
  else
    if M._command_exists("pip") then
      M._run_in_terminal("pip install -r requirements.txt")
    else
      vim.notify("pip command not found", vim.log.levels.ERROR)
    end
  end
end, { desc = "Install from requirements.txt" })

map("n", "<leader>rp", "<cmd>echo 'Use Poetry for dependency management with <leader>o'<CR>", { desc = "Use Poetry (<leader>o)" })

-- =============================================
-- VIRTUAL ENV OPERATIONS (v namespace)
-- =============================================

-- Check if VenvSelector plugin is available
M._has_venv_selector = function()
  if not M._has_plugin("venv-selector") then
    -- If we don't have venv-selector, check if we have our own implementation
    if _G.VenvDiagnostics then
      return true
    end
    vim.notify("VenvSelector plugin not found and VenvDiagnostics is not available", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Smart activation that checks for common environment patterns
map("n", "<leader>va", function()
  if _G.VenvDiagnostics and _G.VenvDiagnostics.smart_activate then
    vim.cmd("VenvActivate")
  elseif M._has_venv_selector() then
    vim.cmd("VenvSelectCached")
  end
end, { desc = "Smart activate Python environment" })

-- Standard VenvSelect for choosing any environment
map("n", "<leader>vs", function()
  if M._has_venv_selector() then
    vim.cmd("VenvSelect")
  end
end, { desc = "Select Python environment" })

-- Cached environment selection
map("n", "<leader>vc", function()
  if M._has_venv_selector() then
    vim.cmd("VenvSelectCached")
  end
end, { desc = "Select cached environment" })

-- Create a new virtual environment
map("n", "<leader>vn", function()
  if _G.VenvDiagnostics and _G.VenvDiagnostics.create_venv then
    vim.cmd("VenvCreate")
  elseif M._has_command("python") then
    local venv_name = vim.fn.input("Virtual environment name (.venv): ", ".venv")
    if venv_name == "" then
      venv_name = ".venv"
    end
    M._run_in_terminal("python -m venv " .. venv_name)
  else
    vim.notify("Python not found", vim.log.levels.ERROR)
  end
end, { desc = "Create new venv" })

-- Show environment info
map("n", "<leader>vi", function()
  if _G.VenvDiagnostics then
    vim.cmd("VenvDiagnostics")
  else
    vim.notify("VenvDiagnostics module not available", vim.log.levels.ERROR)
  end
end, { desc = "Show environment info" })

-- Run diagnostics on current environment
map("n", "<leader>vd", function()
  if _G.VenvDiagnostics then
    vim.cmd("VenvDiagnostics")
  else
    vim.notify("VenvDiagnostics module not available", vim.log.levels.ERROR)
  end
end, { desc = "Run venv diagnostics" })

-- Test current environment
map("n", "<leader>vt", function()
  if _G.VenvDiagnostics and vim.api.nvim_command_exists("TestVenv") then
    vim.cmd("TestVenv")
  else
    vim.notify("TestVenv command not available", vim.log.levels.ERROR)
  end
end, { desc = "Test current venv" })

-- Run current file with venv
map("n", "<leader>vr", function()
  if _G.VenvDiagnostics and _G.VenvDiagnostics.run_with_env then
    vim.cmd("RunPythonWithEnv")
  else
    M._python_run_file()
  end
end, { desc = "Run file with venv" })

-- =============================================
-- EXECUTE CODE OPERATIONS (x namespace)
-- =============================================

-- Python execution and file operations 
map("n", "<leader>xr", function()
  if _G.VenvDiagnostics and _G.VenvDiagnostics.run_with_env then
    vim.cmd("RunPythonWithEnv")
  else
    M._python_run_file()
  end
end, { desc = "Run current file" })

map("n", "<leader>xe", function() M._python_execute_snippet() end, { desc = "Execute selection" })

map("n", "<leader>xi", function() 
  if M._command_exists("ipython") then
    M._python_execute_in_ipython() 
  else
    vim.notify("IPython not installed. Please install it first.", vim.log.levels.ERROR)
  end
end, { desc = "Run in IPython" })

map("n", "<leader>xn", function() M._python_new_file() end, { desc = "New Python file" })

map("n", "<leader>xt", function()
  if M._has_telescope() and pcall(require, "telescope").extensions.python_tests then
    vim.cmd("Telescope python_tests")
  else
    vim.notify("Telescope python_tests extension not available", vim.log.levels.ERROR)
    -- Fall back to running pytest directly if available
    if M._command_exists("pytest") then
      M._run_in_terminal("pytest")
    end
  end
end, { desc = "Run tests" })

map("n", "<leader>xp", "<cmd>echo 'Use <leader>o for Poetry dependency management'<CR>", { desc = "Dependency management ⟶ <leader>o" })

map("n", "<leader>xv", function()
  if _G.VenvDiagnostics and _G.VenvDiagnostics.smart_activate then
    vim.cmd("VenvActivate")
  elseif M._has_venv_selector() then
    vim.cmd("VenvSelectCached")
  end
end, { desc = "Activate virtual environment" })

-- =============================================
-- KEYMAPS HELPER (k namespace)
-- =============================================

-- Check if which-key is available
M._has_which_key = function()
  if not M._has_plugin("which-key") then
    vim.notify("Which-key plugin not found. Please install folke/which-key.nvim", vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Register whichkey specific activate command
map("n", "<leader>k", function()
  if M._has_which_key() then
    vim.cmd("WhichKey")
  end
end, { desc = "Show all keybindings" })

-- =============================================
-- GIT OPERATIONS (g namespace)
-- =============================================

-- Check if LazyGit is available
M._has_lazygit = function()
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("LazyGit executable not found. Please install lazygit", vim.log.levels.ERROR)
    return false
  end
  
  if not M._has_plugin("lazygit.nvim") then
    vim.notify("LazyGit plugin not found. Please install kdheepak/lazygit.nvim", vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- LazyGit mappings
map("n", "<leader>gg", function()
  if M._has_lazygit() then
    vim.cmd("LazyGit")
  end
end, { desc = "Open LazyGit" })

map("n", "<leader>gc", function()
  if M._has_lazygit() then
    vim.cmd("LazyGitConfig")
  end
end, { desc = "LazyGit config" })

map("n", "<leader>gf", function()
  if M._has_lazygit() then
    vim.cmd("LazyGitCurrentFile")
  end
end, { desc = "LazyGit current file" })

map("n", "<leader>gF", function()
  if M._has_lazygit() then
    vim.cmd("LazyGitFilter")
  end
end, { desc = "LazyGit filter" })

map("n", "<leader>gb", function()
  if M._has_lazygit() then
    vim.cmd("LazyGitFilterCurrentFile")
  end
end, { desc = "LazyGit branches" })

-- Git window commands (telescope integration)
map("n", "<leader>gB", function()
  if M._has_telescope() then
    vim.cmd("Telescope git_branches")
  end
end, { desc = "Git branches" })

map("n", "<leader>gC", function()
  if M._has_telescope() then
    vim.cmd("Telescope git_commits")
  end
end, { desc = "Git commits" })

map("n", "<leader>gS", function()
  if M._has_telescope() then
    vim.cmd("Telescope git_status")
  end
end, { desc = "Git status" })

map("n", "<leader>gd", function()
  if M._has_telescope() then
    vim.cmd("Telescope git_bcommits")
  end
end, { desc = "Git diff this buffer" })

-- Function for gitsigns keybindings setup
M.setup_git_mappings = function(gitsigns)
  -- Navigation
  map("n", "]c", function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      gitsigns.next_hunk()
    end)
    return "<Ignore>"
  end, { expr = true, desc = "Next hunk" })

  map("n", "[c", function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      gitsigns.prev_hunk()
    end)
    return "<Ignore>"
  end, { expr = true, desc = "Previous hunk" })

  -- Actions
  map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Stage hunk" })
  map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Reset hunk" })
  map("v", "<leader>gs", function()
    gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, { desc = "Stage hunk" })
  map("v", "<leader>gr", function()
    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end, { desc = "Reset hunk" })
  map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Stage buffer" })
  map("n", "<leader>gu", gitsigns.undo_stage_hunk, { desc = "Undo stage hunk" })
  map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Reset buffer" })
  map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Preview hunk" })
  map("n", "<leader>gl", function()
    gitsigns.blame_line({ full = true })
  end, { desc = "Blame line" })
  map("n", "<leader>gL", gitsigns.toggle_current_line_blame, { desc = "Toggle line blame" })
  map("n", "<leader>gD", gitsigns.diffthis, { desc = "Diff this" })
  map("n", "<leader>gx", function()
    gitsigns.toggle_deleted()
  end, { desc = "Toggle deleted" })
end

-- Function for diagnostic window keybindings
M.setup_diagnostic_window_mappings = function(buf)
  -- Add keybindings for the diagnostic window
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':q<CR>', { noremap = true, silent = true })
end

-- =============================================
-- LSP MAPPINGS
-- =============================================

-- Function for LSP keybindings that is called on LspAttach
M.setup_lsp_mappings = function(bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  
  -- Buffer local mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local opts = { buffer = bufnr, noremap = true, silent = true }
  
  -- Go to definition/references commands
  map("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
  map("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Go to references" })
  map("n", "gi", vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
  map("n", "gt", vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Go to type definition" })
  
  -- Documentation and signature help
  map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Show documentation" })
  map("n", "<C-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Show signature help" })
  
  -- Code actions and workspace management
  map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code actions" })
  map("n", "<leader>cr", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
  map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, { buffer = bufnr, desc = "Format code" })
  
  -- Diagnostics
  map("n", "<leader>cd", vim.diagnostic.open_float, { buffer = bufnr, desc = "Line diagnostics" })
  map("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "Previous diagnostic" })
  map("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "Next diagnostic" })
  map("n", "<leader>cq", vim.diagnostic.setloclist, { buffer = bufnr, desc = "List all diagnostics" })
  
  -- Workspace management
  map("n", "<leader>cw", vim.lsp.buf.add_workspace_folder, { buffer = bufnr, desc = "Add workspace folder" })
  map("n", "<leader>cW", vim.lsp.buf.remove_workspace_folder, { buffer = bufnr, desc = "Remove workspace folder" })
  map("n", "<leader>cl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, { buffer = bufnr, desc = "List workspace folders" })
end

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Helper function to get visual selection
function vim.api.nvim_buf_get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]
  
  -- Get lines in the selection
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  -- If there's only one line in the selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    -- Adjust first and last lines of the selection
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end
  
  return lines
end

-- =============================================
-- KEYBINDING CHEATSHEET
-- =============================================

-- Show all custom mappings in a Telescope window
map("n", "<leader>?", function()
  if pcall(require, "telescope.builtin") then
    require('telescope.builtin').keymaps({
      prompt_title = 'All Keymaps',
      only_buf = false,
    })
  else
    vim.cmd('map')
    vim.notify("Telescope not found, showing default :map", vim.log.levels.INFO)
  end
end, { desc = "Show all keymaps (cheatsheet)" })

-- =============================================
-- GROUPED, MECE MAPPINGS
-- =============================================
-- All mappings are grouped by namespace and have clear, non-overlapping descriptions
-- Buffer operations (b), File explorer (e), Terminal (t), Git (g), Docs (d), Venv (v), Window (w), Search (s), Tabs (tn), UndoTree (u)
-- Each group is registered with which-key for discoverability
if pcall(require, "which-key") then
  local wk = require("which-key")
  wk.register({
    ["<leader>b"] = { name = "+buffer" },
    ["<leader>e"] = { name = "+explorer" },
    ["<leader>t"] = { name = "+terminal" },
    ["<leader>g"] = { name = "+git" },
    ["<leader>d"] = { name = "+docs" },
    ["<leader>v"] = { name = "+venv" },
    ["<leader>w"] = { name = "+window" },
    ["<leader>s"] = { name = "+search" },
    ["<leader>tn"] = { name = "+tabs" },
    ["<leader>u"] = { name = "+undotree" },
    ["<leader>?"] = { "Show all keymaps (cheatsheet)" },
  })
  
  -- WSL-specific registrations
  if is_wsl then
    wk.register({
      ["<leader>fw"] = { "Browse Windows home" },
      ["<leader>wi"] = { 
        name = "+windows",
        e = "Open in Windows Explorer",
        c = "Copy to Windows clipboard",
        v = "Open in VSCode",
        p = "Open in PowerShell",
        w = "Browse Windows home",
      },
    })
  end
end

-- Export the module
return M
