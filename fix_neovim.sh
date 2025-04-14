#!/bin/bash
set -e

echo "=== Starting Neovim configuration fix ==="
echo "1. Cleaning up broken plugins"

# Clean up the problematic plugins
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter-textobjects
rm -rf ~/.local/share/nvim/lazy/wilder.nvim

# Clean parsers directory
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter/parser

echo "2. Reinstalling plugins with Lazy"
cd ~/.config/nvim

# Create a temporary init file that only loads the essential plugins
cat > /tmp/minimal_init.lua << 'EOF'
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "python", "bash", "c", "cpp", "go", "javascript", "typescript", "json" },
        auto_install = true,
        highlight = { enable = true },
        incremental_selection = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "gelguy/wilder.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    build = ":UpdateRemotePlugins",
  },
})
EOF

# Run the minimal init to reinstall only the problematic plugins
nvim --headless -u /tmp/minimal_init.lua '+Lazy! sync' +qa

echo "3. Compiling Treesitter parsers"
nvim --headless -u /tmp/minimal_init.lua '+TSUpdate' +qa

echo "4. Final verification"
nvim --headless -u /tmp/minimal_init.lua '+checkhealth nvim-treesitter' '+checkhealth wilder' +qa

echo "5. Cleanup"
rm /tmp/minimal_init.lua

echo "=== Fix completed ==="
echo "You can now run 'nvim' to use your full configuration"
