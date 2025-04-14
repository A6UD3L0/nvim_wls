-- Streamlined Neovim Configuration for Backend Development and Data Science
-- Based on ThePrimeagen's style with NvChad simplicity
-- WSL-optimized version (Windows Subsystem for Linux)

-- Set leader key to space (must be before lazy bootstrap)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Detect WSL
local is_wsl = (function()
  local output = vim.fn.system('uname -r')
  return output:lower():match('microsoft') ~= nil or output:lower():match('wsl') ~= nil
end)()

-- WSL specific settings
local wsl_paths = {
  windows_home = (function()
    local candidates = {}
    
    -- Only add paths with non-nil environment variables
    if os.getenv("USER") then
      table.insert(candidates, "/mnt/c/Users/" .. os.getenv("USER"))
    end
    
    if os.getenv("USERNAME") then
      table.insert(candidates, "/mnt/c/Users/" .. os.getenv("USERNAME"))
    end
    
    -- Add a fallback option
    table.insert(candidates, "/mnt/c/Users")
    
    for _, path in ipairs(candidates) do
      if vim.fn.isdirectory(path) == 1 then
        return path
      end
    end
    
    return "/mnt/c/Users"
  end)()
}

-- Setup Windows clipboard integration for WSL
if is_wsl then
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
  vim.notify("WSL detected - Windows clipboard integration enabled")
end

-- Create a compatibility layer for Neovim 0.9 vs 0.10+
local nvim_compat = {}
-- Check if we're on Neovim 0.9 (vs 0.10+)
nvim_compat.is_nvim_09 = (function()
  local v = vim.version()
  return v.major == 0 and v.minor < 10
end)()

-- Override functions that might not exist in Neovim 0.9
if nvim_compat.is_nvim_09 then
  -- Some Neovim 0.10+ functions don't exist in 0.9, create compatible alternatives
  vim.api.nvim_set_hl = vim.api.nvim_set_hl or function(ns, name, val)
    local cmd = string.format("highlight %s guifg=%s guibg=%s", name, val.fg or "NONE", val.bg or "NONE")
    vim.cmd(cmd)
  end
  
  -- Adjust setting syntax for splitkeep which doesn't exist in 0.9
  vim.opt.splitkeep = nil
end

-- Bootstrap and configure lazy.nvim (plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", 
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- UI Tweaks for a better experience
vim.opt.termguicolors = true               -- Enable 24-bit RGB colors
vim.opt.number = true                      -- Show line numbers
vim.opt.relativenumber = true              -- Show relative line numbers
vim.opt.cursorline = true                  -- Highlight the current line
vim.opt.scrolloff = 8                      -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8                  -- Keep 8 columns left/right of cursor
vim.opt.showmode = false                   -- Don't show mode (shown in statusline)
vim.opt.signcolumn = "yes"                 -- Always show the signcolumn
vim.opt.wrap = false                       -- Don't wrap lines by default
vim.opt.linebreak = true                   -- Wrap at word boundaries if wrap is on
vim.opt.list = true                        -- Show whitespace characters
vim.opt.listchars = {                      -- Configure whitespace characters
  tab = "→ ",
  trail = "·",
  extends = "▶",
  precedes = "◀",
  nbsp = "␣",
}
vim.opt.fillchars:append({                 -- Make splits look nicer
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vert = "┃",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
})
vim.opt.mouse = "a"                        -- Enable mouse in all modes
vim.opt.splitbelow = true                  -- Open new horizontal splits below
vim.opt.splitright = true                  -- Open new vertical splits to the right
vim.opt.pumheight = 15                     -- Maximum number of items in popup menu
vim.opt.pumblend = 10                      -- Pseudo-transparency for popup menu
vim.opt.winblend = 10                      -- Pseudo-transparency for floating windows

-- Enhanced window/pane management
vim.opt.equalalways = true                 -- Make window size equal when splitting
vim.opt.splitkeep = "screen"               -- Keep text on same screen line when splitting

-- Enhanced window decorations and visual cues
vim.opt.winbar = "%=%m %f"                 -- Show file path in window bar
vim.opt.title = true                       -- Show file in terminal title
vim.opt.colorcolumn = "100"                -- Show a ruler at column 100
vim.opt.cursorlineopt = "both"             -- Highlight both line number and text line

-- Better command-line experience
vim.opt.cmdheight = 1                      -- Height of the command line
vim.opt.laststatus = 3                     -- Global statusline
vim.opt.showcmd = true                     -- Show commands as you type them
vim.opt.wildmode = "longest:full,full"     -- Command line completion mode
vim.opt.wildoptions = "pum"                -- Use popup menu for wildmode

-- Searching
vim.opt.hlsearch = true                    -- Highlight search matches
vim.opt.incsearch = true                   -- Show matches as you type
vim.opt.ignorecase = true                  -- Ignore case when searching
vim.opt.smartcase = true                   -- Don't ignore case with capital letters

-- Make backspace behave normally
vim.opt.backspace = "indent,eol,start"

-- Enable soft word wrapping for markdown and text files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- Editor settings
vim.opt.tabstop = 4             -- Number of spaces tabs count for
vim.opt.softtabstop = 4         -- Number of spaces in tab when editing
vim.opt.shiftwidth = 4          -- Number of spaces to use for autoindent
vim.opt.expandtab = true        -- Tabs are spaces
vim.opt.smartindent = true      -- Insert indents automatically
vim.opt.swapfile = false        -- Don't use swapfile
vim.opt.backup = false          -- Don't create backup files
vim.opt.undofile = true         -- Enable persistent undo
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir" -- Where to store undo history
vim.opt.updatetime = 50         -- Faster completion
vim.opt.colorcolumn = "80"      -- Show column marker at 80 characters
vim.opt.clipboard = "unnamedplus" -- Use system clipboard

-- Command line UI improvements
vim.opt.wildmenu = true         -- Command-line completion
vim.opt.wildmode = "longest:full,full" -- Complete till longest common string, then start wildmenu
vim.opt.cmdheight = 1           -- Command-line height
vim.opt.laststatus = 3          -- Global statusline
vim.opt.showmatch = true        -- Jump to matching bracket briefly

-- Better display of invisibles
vim.opt.list = true
vim.opt.listchars = {
  tab = "» ",
  trail = "·",
  extends = "›",
  precedes = "‹",
  nbsp = "␣",
}

-- Better search experience
vim.opt.ignorecase = true       -- Ignore case in search
vim.opt.smartcase = true        -- Unless search has uppercase
vim.opt.incsearch = true        -- Show matches as you type
vim.opt.hlsearch = true         -- Highlight search results

-- Buffer settings
vim.opt.hidden = true           -- Allow switching from unsaved buffers
vim.opt.confirm = true          -- Confirm changes when exiting buffers
vim.opt.completeopt = "menuone,noselect" -- Better completion experience

-- Disable unused providers to remove health check warnings
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Configure Python provider
if vim.fn.has('macunix') == 1 then
  -- macOS Python path
  vim.g.python3_host_prog = vim.fn.expand('~/.venvs/neovim/bin/python3')
elseif vim.fn.has('unix') == 1 then
  -- Linux Python path - adjust if needed
  vim.g.python3_host_prog = vim.fn.expand('~/.venvs/neovim/bin/python3')
elseif vim.fn.has('win32') == 1 then
  -- Windows Python path - adjust if needed
  vim.g.python3_host_prog = vim.fn.expand('~/AppData/Local/Programs/Python/Python39/python.exe')
end

-- Unset VIRTUAL_ENV to prevent the Python virtualenv warning
if vim.env.VIRTUAL_ENV then
  -- Store the original value in case we need it later
  vim.g.original_virtual_env = vim.env.VIRTUAL_ENV
  -- Unset it to avoid the warning
  vim.env.VIRTUAL_ENV = nil
end

-- Ensure data directories exist
local function ensure_dir(path)
  local stat = vim.loop.fs_stat(path)
  if not stat then
    vim.fn.mkdir(path, "p")
  end
end

-- Create necessary data directories
ensure_dir(vim.fn.stdpath("data") .. "/undodir")
ensure_dir(vim.fn.stdpath("data") .. "/backup")
ensure_dir(vim.fn.stdpath("data") .. "/swap")
ensure_dir(vim.fn.stdpath("data") .. "/shada")

-- Load mappings
require("mappings")

-- Load backend-essential configurations
local backend = require("backend-essentials")

-- Set up plugin management with Lazy
require("lazy").setup({
  -- Core plugins
  { import = "plugins" },
  
  -- Linting and formatting
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("lint").linters_by_ft = {
        python = {"flake8", "mypy"},
        lua = {"luacheck"},
        go = {"golangci-lint"},
      }
      
      -- Run lint on save
      vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "black", "isort" },
          go = { "gofmt", "goimports" },
          lua = { "stylua" },
          json = { "jq" },
          yaml = { "yamlfmt" },
          sql = { "sqlfluff" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },
  
  -- UI Improvements
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    config = function()
      require("dressing").setup({
        input = {
          enabled = true,
          default_prompt = "Input:",
          prompt_align = "left",
          insert_only = true,
          border = "rounded",
          relative = "cursor",
          win_options = {
            winblend = 10,
            wrap = false,
          },
        },
        select = {
          enabled = true,
          backend = { "telescope", "fzf", "builtin" },
          trim_prompt = true,
          border = "rounded",
        },
      })
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        signature = {
          enabled = true,
          auto_open = {
            enabled = true,
            trigger = true,
            luasnip = true,
            throttle = 50,
          },
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = true,
        lsp_doc_border = true,
      },
    },
  },

}, {
  install = {
    colorscheme = { "rose-pine" },
  },
  ui = {
    border = "rounded",
    icons = {
      cmd = "⌘",
      config = "🛠️",
      event = "📅",
      ft = "📂",
      init = "⚙️",
      keys = "🔑",
      plugin = "🔌",
      runtime = "💻",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- Language-specific settings for backend development
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "go", "c", "cpp", "sql", "dockerfile", "yaml", "json" },
  callback = function()
    -- Set appropriate indent for backend languages
    vim.opt_local.expandtab = true
    
    -- Different indent sizes for specific languages
    if vim.bo.filetype == "python" or vim.bo.filetype == "go" then
      vim.opt_local.tabstop = 4
      vim.opt_local.softtabstop = 4
      vim.opt_local.shiftwidth = 4
    elseif vim.bo.filetype == "yaml" or vim.bo.filetype == "json" then
      vim.opt_local.tabstop = 2
      vim.opt_local.softtabstop = 2
      vim.opt_local.shiftwidth = 2
    end
  end
})

-- Python-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    -- Maximum line length indicator per PEP 8
    vim.opt_local.colorcolumn = "88"
    
    -- Enable docstring folding
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "nvim_treesitter#foldexpr()"
    
    -- Start unfolded
    vim.opt_local.foldenable = false
  end
})

-- Load venv_diagnostics module
local venv_ok, venv_diagnostics = pcall(require, "venv_diagnostics")
if venv_ok then
  _G.VenvDiagnostics = venv_diagnostics
end

-- Set up commands for commonly used functions
vim.api.nvim_create_user_command("Format", function()
  if require("conform") then
    require("conform").format()
  else
    vim.lsp.buf.format({ async = true })
  end
end, { desc = "Format current buffer with LSP or formatter" })

-- Initialize backend development tools after plugins are loaded
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    -- Setup backend development features
    backend.setup_lsp()
    backend.setup_tools()
    backend.setup_debugging()
    
    -- Show message on first installation
    if vim.fn.filereadable(vim.fn.stdpath("config") .. "/.installed") == 0 then
      vim.api.nvim_create_autocmd("User", {
        pattern = "MasonToolsUpdateCompleted",
        callback = function()
          vim.defer_fn(function()
            vim.cmd([[
              echohl WarningMsg
              echo "Installation complete! Backend Development environment is ready."
              echohl None
            ]])
            vim.fn.writefile({}, vim.fn.stdpath("config") .. "/.installed")
          end, 1000)
        end,
        once = true,
      })
    end
  end,
})

-- Initialize WSL specific utilities
if is_wsl then
  -- Load and setup the WSL module (after plugins are loaded)
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    callback = function()
      local wsl = require("wsl")
      wsl.setup_mappings()
    end,
  })
end

-- Set up auto commands
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "go", "c", "cpp", "sql", "dockerfile", "yaml", "json" },
  callback = function()
    -- Set appropriate indent for backend languages
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    
    -- Special settings for specific filetypes
    if vim.bo.filetype == "go" then
      vim.opt_local.expandtab = false
      vim.opt_local.shiftwidth = 4
      vim.opt_local.tabstop = 4
    elseif vim.bo.filetype == "python" then
      vim.opt_local.colorcolumn = "88" -- Black formatter uses 88 characters
    end
  end
})

-- Ensure terminal opens in the bottom center
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})

-- Set up automatic filetype detection for backend files
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.py", "*.go", "*.rs", "*.ts", "*.java", "*.c", "*.cpp", "*.h", "*.hpp" },
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.relativenumber = true
  end,
})

-- Set easier to read tab settings for certain filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "css", "javascript", "typescript", "json", "yaml", "lua" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Automatically format Go files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    vim.lsp.buf.format()
  end,
})

-- Trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Fix common typos in command mode
vim.cmd([[
  cnoreabbrev W w
  cnoreabbrev Q q
  cnoreabbrev Wq wq
  cnoreabbrev WQ wq
  cnoreabbrev Qa qa
  cnoreabbrev Wqa wqa
]])

-- Set shorter updatetime for faster response
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500

-- Notify about environment
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    if is_wsl then
      vim.notify("Neovim " .. vim.version().major .. "." .. vim.version().minor .. 
                " running in WSL with Windows integration", vim.log.levels.INFO)
    end
  end,
})
