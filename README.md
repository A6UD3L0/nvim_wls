# Ultimate Backend Development Neovim Configuration for WSL

A comprehensive Neovim configuration optimized for backend development and data science, specially adapted for **Windows Subsystem for Linux (WSL)**. This configuration combines ThePrimeagen's powerful keybindings with NvChad's simplicity for an efficient development experience with beautiful UI elements, plus seamless Windows integration.

![Neovim Dashboard](https://raw.githubusercontent.com/A6UD3L0/nvim-config/main/assets/dashboard.png)

## 🚀 Features

- **Gorgeous UI**
  - Rose Pine theme with customized transparency
  - Beautiful welcome dashboard with Alpha
  - Integrated file explorer with NvimTree
  - Modern statusline with Lualine
  - Tab and buffer management with Barbar

- **Python Development Arsenal**
  - Poetry integration for seamless package management
  - Virtual environment handling with automatic detection
  - Requirements.txt generation and installation shortcuts
  - Python debugging with DAP integration
  - Integrated REPL with Python and IPython support

- **Machine Learning & Data Science**
  - Integrated documentation for ML libraries (scikit-learn, NumPy, Pandas)
  - Direct shortcuts to TensorFlow, PyTorch, and Matplotlib documentation
  - Virtual environment management optimized for data science workflows
  - Intelligent code completion for ML libraries
  - Notebook-like experience with code execution

- **Backend Language Support**
  - First-class support for Python, Go, Rust, TypeScript, SQL
  - Docker and Kubernetes integration
  - Database clients and SQL execution
  - LSP integration with intelligent code actions
  - Treesitter for advanced syntax highlighting

- **Intelligent Code Assistance**
  - GitHub Copilot integration
  - Completion with nvim-cmp
  - Snippets with LuaSnip
  - Automated import management
  - Advanced code diagnostics and linting

- **Efficient Git Workflow**
  - Gitsigns for inline git information
  - LazyGit for visual Git operations
  - Diffview for code comparison
  - Merge conflict resolution tools

- **Productivity Boosters**
  - Terminal integration with Toggleterm
  - Project management with Telescope
  - MECE-compliant keybinding system with logical namespaces
  - File navigation with Telescope fuzzy finder
  - Undotree for change history visualization

## 🔄 WSL & Windows Integration

This configuration is specifically designed for use in WSL (Ubuntu) with Neovim 0.9+ and includes enhanced Windows integration. It allows you to seamlessly work with Windows files directly from your WSL Neovim environment.

### Windows Integration Features

- **Automatic Path Conversion**: Intelligently converts between Windows and WSL paths
  - Handles Windows-style paths (`C:\Users\name`) in WSL
  - Converts WSL paths (`/mnt/c/Users/name`) to Windows format when needed
  - Special handling for home directory (`~`) path conversion

- **Windows Clipboard Integration**: Seamless copy/paste between WSL and Windows
  - Uses Windows `clip.exe` for copying content to Windows clipboard
  - Uses PowerShell to paste from Windows clipboard
  - Handles line ending differences automatically

- **Windows File System Navigation**: Quick access to important Windows directories
  - Fast access to Windows Home directory (`C:\Users\<username>`)
  - Direct navigation to Windows Documents folder
  - Direct navigation to Windows Desktop folder
  - Full Telescope fuzzy finder integration for Windows file browsing

- **Windows Application Integration**: Open files with native Windows applications
  - Open current file/folder in Windows Explorer
  - Launch Visual Studio Code for the current file
  - Open PowerShell in the current directory
  - Automatic file path correction for cross-platform compatibility

- **Automatic File Path Correction**: Fixes path issues when opening files
  - Detects and corrects Windows-style paths when opening files
  - Automatically handles Windows UNC paths (`\\server\share`)
  - Fixes path issues with buffers and commands

### WSL-Specific Keybindings

All Windows integration features are available through the `<leader>w` prefix:

| Binding           | Action                                       |
|-------------------|--------------------------------------------- |
| `<leader>we`      | Open current file in Windows Explorer        |
| `<leader>wc`      | Copy to Windows clipboard                    |
| `<leader>wv`      | Open current file in VSCode                  |
| `<leader>wp`      | Open PowerShell in current directory         |
| `<leader>wh`      | Go to Windows user home directory            |
| `<leader>wd`      | Go to Windows Documents folder               |
| `<leader>wk`      | Go to Windows Desktop folder                 |
| `<leader>wf`      | Browse Windows home files with Telescope     |
| `<leader>wb`      | Browse Windows Desktop files with Telescope  |

### How Path Conversion Works

This configuration includes a comprehensive path conversion system that makes working with files across Windows and WSL seamless:

1. **Windows to WSL Path Conversion**:
   - Converts `C:\path\to\file.txt` to `/mnt/c/path/to/file.txt`
   - Handles UNC paths, drive letters, and special Windows directories

2. **WSL to Windows Path Conversion**:
   - Converts `/mnt/c/path/to/file.txt` to `C:\path\to\file.txt`
   - Handles home directory expansion for proper cross-platform mapping
   - Preserves paths that shouldn't be converted

3. **Automatic Path Correction**:
   - When opening a file with Windows path syntax in WSL, it automatically corrects the path
   - Special BufReadCmd and FileReadCmd autocmds ensure smooth editor operation
   - Improves compatibility with Telescope, Netrw, and other file browsers

## 📋 System Requirements

- Neovim 0.9.0 or higher
- Git
- Node.js and npm (for LSP servers)
- Python 3.8+ with pip (for Python language support)
- Rust/Cargo (for language servers)
- Ripgrep (for Telescope searches)
- A Nerd Font (for icons)
- WSL (Windows Subsystem for Linux) with Ubuntu
- Windows terminal or similar for proper rendering

### WSL-Specific Requirements

- Windows Subsystem for Linux (WSL2 recommended)
- Ubuntu 20.04 or newer WSL distribution 
- Windows Terminal for best experience
- Windows Clipboard access (`clip.exe` and PowerShell)
- Windows path access permissions

## ⚡ MECE Keybinding Structure

This configuration uses a **M**utually **E**xclusive, **C**ollectively **E**xhaustive (MECE) keybinding structure for maximum efficiency and intuitiveness:

| Namespace    | Purpose                                     |
|--------------|---------------------------------------------|
| `<leader>b`  | Buffer operations                           |
| `<leader>c`  | Code editing (formatting, styling)          |
| `<leader>d`  | Documentation (devdocs, help)               |
| `<leader>dm` | Machine Learning documentation              |
| `<leader>e`  | Explorer operations                         |
| `<leader>f`  | Find/File operations                        |
| `<leader>g`  | Git operations                              |
| `<leader>h`  | Harpoon operations                          |
| `<leader>k`  | Keymaps (show key bindings, help)           |
| `<leader>l`  | LSP operations (diagnostics, actions)       |
| `<leader>o`  | Organize (Poetry package management)        |
| `<leader>p`  | Project operations                          |
| `<leader>r`  | Run/Requirements                            |
| `<leader>s`  | Search/Replace operations                   |
| `<leader>t`  | Terminal/Tab operations                     |
| `<leader>u`  | Utilities (undotree, helpers)               |
| `<leader>v`  | Virtual environment (Python venv)           |
| `<leader>w`  | Window and WSL-Windows integration          |
| `<leader>x`  | Execute code (run scripts, REPL)            |
| `<leader>z`  | Zen/Focus mode                              |

### Documentation Keybindings

Documentation is accessible through the `<leader>d` namespace with ML-specific documentation under `<leader>dm`:

| Binding           | Action                                    |
|-------------------|-------------------------------------------|
| `<leader>do`      | Toggle documentation panel                |
| `<leader>dO`      | Open documentation in buffer              |
| `<leader>df`      | Fetch documentation index                 |
| `<leader>di`      | Install documentation                     |
| `<leader>du`      | Update documentation                      |
| `<leader>dU`      | Update all documentation                  |
| `<leader>dh`      | Search in documentation                   |
| `<leader>dm`      | Browse ML documentation (interactive)     |
| `<leader>dmk`     | scikit-learn documentation               |
| `<leader>dmn`     | NumPy documentation                       |
| `<leader>dmp`     | Pandas documentation                      |
| `<leader>dmt`     | TensorFlow documentation                  |
| `<leader>dmy`     | PyTorch documentation                     |
| `<leader>dmm`     | Matplotlib documentation                  |

## 🔑 Key Productivity Shortcuts

- `jk` - Exit insert mode (faster than pressing Escape)
- `<C-h/j/k/l>` - Navigate between windows without using leader key
- `<leader>we` - Make all windows equal size
- `<leader>e` - Toggle file explorer
- `<leader>ff` - Find files
- `<leader>fg` - Find text in files (grep)
- `<leader>u` - Toggle Undotree
- `<leader>gg` - Open LazyGit
- `<leader>tt` - Toggle terminal
- `<leader>do` - Open documentation in a pane with search capabilities
- `<leader>dm` - Browse ML library documentation interactively
- `<leader>dmk` - Quick access to scikit-learn documentation
- `<leader>vr` - Run Python file with virtual environment
- `<leader>oi` - Install Poetry dependencies

## 🔧 Installation

### Quick Start (Automated)

The easiest way to install this configuration is to use the included installation script:

```bash
# Clone the repository
git clone https://github.com/A6UD3L0/nvim_wls.git
cd nvim_wls

# Run the installation script
./install.sh
```

### Manual Installation

#### For WSL (Ubuntu):

```bash
# Update packages
sudo apt update

# Install dependencies
sudo apt install -y neovim ripgrep fd-find git curl wget nodejs npm python3 python3-pip python3-venv

# Create Python virtual environment for Neovim
mkdir -p ~/.venvs/neovim
python3 -m venv ~/.venvs/neovim
~/.venvs/neovim/bin/pip install pynvim

# Install Neovim configuration
git clone https://github.com/A6UD3L0/nvim_wls.git ~/.config/nvim
```

#### Prerequisites for Windows Integration

For the best WSL-Windows integration experience, ensure:

1. Your WSL distribution can access Windows binaries:
   - `clip.exe` (for clipboard)
   - `explorer.exe` (for file explorer) 
   - `code.exe` (for VSCode)
   - `powershell.exe` (for PowerShell)

2. Your Windows Terminal has access between Linux and Windows:
   - WSL integration enabled
   - Clipboard integration enabled
   - Proper font with icons configured

## 🔄 WSL-Windows Integration Setup

The configuration automatically detects WSL and sets up appropriate integrations, but you can customize it further:

1. **Early WSL detection**: The configuration detects WSL at startup:
   ```lua
   -- Detect WSL
   local is_wsl = (function()
     local output = vim.fn.system('uname -r')
     return output:lower():match('microsoft') ~= nil or output:lower():match('wsl') ~= nil
   end)()
   ```

2. **WSL module auto-loading**: The WSL integration module loads automatically:
   ```lua
   -- Load WSL utilities early
   if is_wsl then
     local ok, wsl_module = pcall(require, 'wsl')
     if ok then
       wsl = wsl_module
       wsl.setup()
     end
   end
   ```

3. **Windows clipboard setup**: Configured for seamless clipboard sharing:
   ```lua
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
   ```

4. **Automatic path correction**: Set up with autocmds for smooth file handling:
   ```lua
   vim.api.nvim_create_autocmd({"BufReadCmd", "FileReadCmd"}, {
     pattern = {"*"},
     callback = function(ev)
       if wsl and wsl.fix_path then
         local fixed_path = wsl.fix_path(ev.file)
         if fixed_path and fixed_path ~= ev.file then
           vim.cmd("edit " .. fixed_path)
           return true
         end
       end
       return false
     end
   })
   ```

## 🔍 Troubleshooting WSL Integration

### Common Issues and Solutions

1. **Can't access Windows files**:
   - Check that your WSL mount points are correctly set up
   - Verify that `/mnt/c` exists and is accessible
   - Try running `explorer.exe .` in your WSL terminal to test Windows access

2. **Clipboard not working between WSL and Windows**:
   - Verify `clip.exe` is available from your WSL terminal
   - Check that PowerShell is accessible from WSL
   - Try running `echo "test" | clip.exe` to test clipboard access

3. **Windows paths not converting correctly**:
   - Check if your username detection is working with `echo $USERNAME` in WSL
   - If detection fails, explicitly set your Windows username in your init.lua:
     ```lua
     vim.g.windows_username = "YourWindowsUsername"
     ```

4. **File paths with special characters not working**:
   - Use proper escaping for paths with spaces or special characters
   - When dealing with problematic paths, try quoting them in your commands

5. **VSCode integration not working**:
   - Make sure `code.exe` is in your Windows PATH and accessible from WSL
   - Try running `code.exe .` from your WSL terminal to test VSCode access

### Resolving Unicode and Special Character Issues

When working with files that contain special characters or Unicode:

```lua
-- Configure better UTF-8 handling
vim.opt.fileencodings = "utf-8,sjis,euc-jp,latin"
vim.opt.encoding = "utf-8"

-- Improve WSL-Windows compatibility for filenames
vim.opt.isfname:append("@-@")
```

## 📝 Customization

### Customizing WSL-Windows Integration

You can customize the WSL integration by editing the `lua/wsl.lua` file:

1. **Add custom Windows applications**:
   ```lua
   -- Open in your preferred Windows application
   M.open_in_app = function(app_name, args)
     local path = vim.fn.expand('%:p')
     local winpath = M.to_windows_path(path)
     local cmd = string.format('%s.exe "%s" %s', app_name, winpath, args or "")
     vim.fn.system(cmd)
     vim.notify(string.format("Opening in %s: %s", app_name, winpath), vim.log.levels.INFO)
   end
   ```

2. **Change keyboard mappings**:
   ```lua
   -- In wsl.lua setup function
   vim.keymap.set("n", "<leader>wx", M.your_custom_function, { desc = "Your custom function" })
   ```

3. **Add custom paths**:
   ```lua
   -- Navigate to a custom Windows location
   M.goto_windows_custom = function()
     local custom_path = "/mnt/c/Path/To/Your/Directory"
     if vim.fn.isdirectory(custom_path) == 1 then
       vim.cmd('cd ' .. custom_path)
       vim.notify("Changed to custom directory: " .. custom_path, vim.log.levels.INFO)
     else
       vim.notify("Custom directory not found: " .. custom_path, vim.log.levels.ERROR)
     end
   end
   ```

## 📚 Advanced Usage

### Seamless WSL-Windows Workflow

This configuration enables seamless workflows across WSL and Windows:

1. **Editing code in WSL, viewing in Windows browsers**:
   - Edit web projects in Neovim on WSL
   - Use `<leader>we` to open in Windows Explorer
   - Run a local server in WSL and access via Windows browsers

2. **Accessing shared files across environments**:
   - Keep your code in `/mnt/c/Users/YourName/Projects`
   - Access it from both WSL Neovim and Windows applications
   - No need to duplicate files between environments

3. **Combining Windows and Linux tools**:
   - Use Linux CLI tools from Neovim
   - Use Windows GUI applications when needed
   - Share files seamlessly between both

### Integration with Windows Development Tools

Use WSL Neovim alongside Windows development tools:

1. **Database Management**:
   - Connect to databases from WSL Neovim
   - Open results in Windows SQL management tools

2. **Git Visual Tools**:
   - Use LazyGit in Neovim for daily operations
   - Open complex merges in Windows GUI tools when needed

3. **Documentation**:
   - Access documentation directly in Neovim
   - Open complex diagrams in Windows browsers

## 🚀 Future Development

Planned enhancements for the WSL integration:

- Improved handling of WSL distributions and Windows Terminal integration
- Enhanced Windows Registry integration for advanced configuration
- Support for Windows network drive paths and UNC paths
- Automatic font installation for WSL terminal

## 🤝 Contributing

Contributions to improve the WSL-Windows integration are welcome:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📄 License

This Neovim configuration is released under the MIT License. See the LICENSE file for details.

---

*This documentation was last updated on April 14, 2025*
