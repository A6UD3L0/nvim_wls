-- Essential plugins for backend development and data science
return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "folke/neodev.nvim",
      "b0o/schemastore.nvim", -- Add SchemaStore for JSON schemas
    },
    config = function()
      -- Setup Mason first to ensure package manager is ready
      require("mason").setup({
        ui = { 
          border = "rounded",
          icons = {
            package_installed = " ",
            package_pending = " ",
            package_uninstalled = " ",
          },
          keymaps = {
            toggle_package_expand = "<CR>",
            install_package = "i",
            update_package = "u",
            check_package_version = "c",
            update_all_packages = "U",
            check_outdated_packages = "C",
            uninstall_package = "X",
            cancel_installation = "<C-c>",
          },
        },
        max_concurrent_installers = 10,
        registries = {
          "github:mason-org/mason-registry",
        },
        log_level = vim.log.levels.INFO,
        install_root_dir = vim.fn.stdpath("data") .. "/mason",
      })
      
      -- Setup Neodev for Lua development
      require("neodev").setup({
        library = { 
          plugins = { "nvim-dap-ui" },
          types = true,
        },
      })
      
      -- Install and configure LSP servers
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Backend languages
          "pyright",           -- Python
          "gopls",             -- Go
          "clangd",            -- C/C++
          "sqlls",             -- SQL
          "dockerls",          -- Docker
          "yamlls",            -- YAML (Kubernetes, CI/CD)
          "jsonls",            -- JSON
          "bashls",            -- Bash
          "lua_ls",            -- Lua
        },
        automatic_installation = true,
      })
      
      -- Install additional tools with mason-tool-installer
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- Formatters
          "black",             -- Python formatter
          "isort",             -- Python import sorter
          "stylua",            -- Lua formatter
          "shfmt",             -- Shell formatter
          "gofumpt",           -- Go formatter
          "goimports",         -- Go imports
          "clang-format",      -- C/C++ formatter
          "prettier",          -- JSON/YAML formatter
          "sqlfluff",          -- SQL formatter
          
          -- Linters
          "flake8",            -- Python linter
          "mypy",              -- Python type checker
          "pylint",            -- Python linter
          "golangci-lint",     -- Go linter
          "hadolint",          -- Dockerfile linter
          "shellcheck",        -- Shell linter
          "luacheck",          -- Lua linter
          
          -- DAP (Debugging)
          "debugpy",           -- Python debugger
          "delve",             -- Go debugger
          "codelldb",          -- C/C++ debugger
        },
        auto_update = true,
        run_on_start = true,
        start_delay = 3000, -- 3 second delay
        debounce_hours = 24, -- Only run once a day
      })
      
      -- Configure LSP capabilities with nvim-cmp
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Configure individual LSP servers
      local lspconfig = require("lspconfig")
      
      -- Lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              diagnosticMode = "workspace",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
              },
            },
          },
        },
      })

      -- Go
      lspconfig.gopls.setup({
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              shadow = true,
            },
            staticcheck = true,
            usePlaceholders = true,
            completeUnimported = true,
          },
        },
      })

      -- JSON with schema support
      lspconfig.jsonls.setup({
        capabilities = capabilities,
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      })

      -- YAML with schema support
      lspconfig.yamlls.setup({
        capabilities = capabilities,
        settings = {
          yaml = {
            schemas = require('schemastore').yaml.schemas(),
            validate = true,
            completion = true,
            hover = true,
            schemaStore = {
              enable = false, -- We're using schemastore.nvim instead
              url = "", -- Not required when enable=false
            },
          },
        },
      })

      -- C/C++
      lspconfig.clangd.setup({
        capabilities = capabilities,
      })
      
      -- SQL
      lspconfig.sqlls.setup({
        capabilities = capabilities,
      })
      
      -- Docker
      lspconfig.dockerls.setup({
        capabilities = capabilities,
      })
      
      -- YAML
      -- lspconfig.yamlls.setup({
      --   capabilities = capabilities,
      --   settings = {
      --     yaml = {
      --       schemas = {
      --         ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
      --         ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml",
      --       },
      --     },
      --   },
      -- })
      
      -- JSON
      -- lspconfig.jsonls.setup({
      --   capabilities = capabilities,
      --   settings = {
      --     json = {
      --       schemas = require('schemastore').json.schemas(),
      --       validate = { enable = true },
      --     },
      --   },
      -- })
      
      -- Bash
      lspconfig.bashls.setup({
        capabilities = capabilities,
      })
      
      -- Lua
      -- lspconfig.lua_ls.setup({
      --   capabilities = capabilities,
      --   settings = {
      --     Lua = {
      --       runtime = {
      --         version = 'LuaJIT',
      --       },
      --       diagnostics = {
      --         globals = { 'vim' },
      --       },
      --       workspace = {
      --         library = vim.api.nvim_get_runtime_file("", true),
      --         checkThirdParty = false,
      --       },
      --       telemetry = {
      --         enable = false,
      --       },
      --     },
      --   },
      -- })
      
      -- Global LSP keymappings (will be mapped by which-key later)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local bufnr = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
          
          -- Load all LSP-related keymappings from the central mappings file
          require("mappings").setup_lsp_mappings(bufnr)
        end,
      })
      
      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })
      
      -- Diagnostic signs
      local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        if vim.fn.has("nvim-0.10") == 1 and vim.fn.sign_define then
          vim.api.nvim_set_hl(0, hl, { default = true })
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        else
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
        end
      end
    end,
  },
  
  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*", -- Use stable version to avoid deprecated warnings
        dependencies = {
          "rafamadriz/friendly-snippets",
          "saadparwaiz1/cmp_luasnip",
          {
            "benfowler/telescope-luasnip.nvim",
          },
        },
        build = (not jit.os:find("Windows")) and 
          "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp" or nil,
        event = "InsertEnter",
        config = function()
          -- Silence the deprecated vim.validate warnings - these come from LuaSnip and will be fixed in future versions
          local orig_validate = vim.validate
          local silent_validate = function(...)
            local suppress_warning = true
            if suppress_warning then
              local orig_notify = vim.notify
              vim.notify = function(msg, level, opts)
                if level == vim.log.levels.WARN and msg:match("vim.validate") then
                  return
                end
                return orig_notify(msg, level, opts)
              end
              local result = orig_validate(...)
              vim.notify = orig_notify
              return result
            else
              return orig_validate(...)
            end
          end
          
          -- Temporarily replace vim.validate with our silent version while loading snippets
          vim.validate = silent_validate
          require("luasnip.loaders.from_vscode").lazy_load()
          require("luasnip").filetype_extend("python", { "django", "pydoc" })
          require("luasnip").filetype_extend("javascript", { "html", "css" })
          require("luasnip").filetype_extend("typescript", { "javascript", "html", "css" })
          require("luasnip").filetype_extend("go", { "godoc" })
          -- Restore original vim.validate
          vim.validate = orig_validate
        end,
      },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      
      require("luasnip.loaders.from_vscode").lazy_load()
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = function(entry, vim_item)
            -- Set maximum width for completion menu items
            local label = vim_item.abbr
            local truncated_label = vim.fn.strcharpart(label, 0, 40)
            if truncated_label ~= label then
              vim_item.abbr = truncated_label .. "..."
            end
            return vim_item
          end,
        },
        window = {
          completion = { 
            border = "rounded",
            scrollbar = true,
          },
          documentation = { 
            border = "rounded" 
          },
        },
      })
    end,
  },
  
  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signcolumn = true,
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        
        -- Use centralized git mappings
        require("mappings").setup_git_mappings(gs)
      end,
    },
  },
  
  -- LazyGit integration
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  
  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
      { "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Find in current buffer" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_workspace_symbols<CR>", desc = "Workspace symbols" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
              ["<esc>"] = actions.close,
            },
          },
          file_ignore_patterns = {
            "node_modules",
            ".git/",
            ".pytest_cache/",
            "__pycache__/",
            "venv/",
            ".venv/",
            "%.pyc",
            "%.pyo",
            "%.obj",
            "%.o",
            "%.a",
            "%.bin",
            "%.tar.gz",
            "%.zip",
            "%.7z",
            "%.so",
          },
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
        },
        pickers = {
          find_files = {
            hidden = true, -- Show hidden files
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
          },
          live_grep = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      
      telescope.load_extension("fzf")
    end,
  },
  
  -- Terminal integration
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm",
    keys = { 
      { "<leader>tt", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Toggle terminal" },
      { "<C-t>", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Toggle terminal with Ctrl+t" },
    },
    opts = {
      open_mapping = [[<c-\>]],
      direction = "horizontal",
      size = function()
        return math.floor(vim.o.lines * 0.3)
      end,
      autochdir = true,
      shade_terminals = true,
      start_in_insert = true,
    },
  },
  
  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
      { "<leader>ef", "<cmd>NvimTreeFocus<CR>", desc = "Focus file explorer" },
    },
    opts = {
      filters = { dotfiles = false },
      disable_netrw = true,
      hijack_netrw = true,
      hijack_cursor = true,
      git = { enable = true, ignore = false },
      view = {
        width = 30, -- Match the width of undotree
        side = "left", -- Position on the left side
        preserve_window_proportions = true, -- Keep editing window large
        signcolumn = "yes",
      },
      actions = {
        open_file = {
          resize_window = true, -- Resize the window upon file open
          window_picker = {
            enable = true,
            chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
            exclude = {
              filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
              buftype = { "terminal", "help" },
            },
          },
        },
      },
      renderer = {
        highlight_git = true,
        indent_markers = { enable = true },
      },
    },
  },
  
  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "go", "lua", "python", "rust", "sql",
          "vim", "vimdoc", "yaml", "json", "toml", "dockerfile",
          "html", "css", "javascript", "typescript", "tsx",
          "markdown", "markdown_inline", "regex", "query",
        },
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "<CR>",
            scope_incremental = "<S-CR>",
            node_decremental = "<BS>",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
  
  -- Harpoon for quick file navigation
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true,
    keys = {
      { "<leader>a", function() require("harpoon"):list():append() end, desc = "Harpoon add file" },
      { "<leader>h", function() local harpoon = require("harpoon") harpoon.ui:toggle_quick_menu(harpoon:list()) end, desc = "Harpoon menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
    },
  },
  
  -- Debugging
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "leoluz/nvim-dap-go",
      "mfussenegger/nvim-dap-python",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio", -- Required by nvim-dap-ui
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dt", function() require("dapui").toggle() end, desc = "Toggle UI" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "Open REPL" },
    },
    config = function()
      require("nvim-dap-virtual-text").setup()
      
      -- DAP UI setup
      local dapui = require("dapui")
      dapui.setup()
      
      -- Automatically open UI when debugging starts
      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      
      -- Go debugging
      require("dap-go").setup()
      
      -- Python debugging
      require("dap-python").setup()
    end,
  },
  
  -- Which-key for keybinding help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = {
          marks = true,      -- shows marks when pressing '
          registers = true,  -- shows registers when pressing "
          spelling = {
            enabled = true,  -- enables whichkey for spell suggestions
            suggestions = 20,
          },
        },
        window = {
          border = "rounded", -- none, single, double, shadow, rounded
          position = "bottom", -- bottom, top
          margin = { 1, 0, 1, 0 }, -- top, right, bottom, left
          padding = { 1, 2, 1, 2 }, -- top, right, bottom, left
        },
        layout = {
          height = { min = 4, max = 25 }, -- min and max height of the columns
          width = { min = 20, max = 50 }, -- min and max width of the columns
          spacing = 3,                    -- spacing between columns
          align = "center",               -- align columns left, center or right
        },
        icons = {
          breadcrumb = "»",  -- Symbol in the command line area
          separator = "➜",   -- Symbol between a key and its label
          group = "+",       -- Symbol prepended to a group
        },
      })
      
      -- Register label namespaces only (all actual keybindings are in mappings.lua)
      wk.register({
        ["<leader>"] = {
          ["<leader>"] = { name = "Show all keybindings" },
          ["b"] = { name = " Buffers" },
          ["c"] = { name = " Code Actions" },
          ["cd"] = { name = " Change Directory" },
          ["cf"] = { name = "Format code" },
          ["d"] = { name = " Debug/Delete" },
          ["do"] = { name = " Documentation" },
          ["e"] = { name = " Explorer" },
          ["f"] = { name = " Find/Files" },
          ["g"] = { name = " Git" },
          ["h"] = { name = " Harpoon" },
          ["l"] = { name = " LSP" },
          ["o"] = { name = " Poetry" },
          ["p"] = { name = " Paste/Project" },
          ["pv"] = { name = "Open Netrw" },
          ["q"] = { name = " Quickfix" },
          ["r"] = { name = " Requirements" },
          ["s"] = { name = "Search and replace" },
          ["t"] = { name = " Terminal" },
          ["u"] = { name = "Toggle Undotree" },
          ["v"] = { name = "󱎫 Python Tools" },
          ["w"] = { name = " Window" },
          ["x"] = { name = "Make executable" },
          ["y"] = { name = " Python" },
        },
        ["w"] = { name = "Window/Write" },
        ["g"] = { name = "Go to" },
      })
    end,
  },
  
  -- Database explorer
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      "tpope/vim-dadbod",
      "kristijanhusak/vim-dadbod-completion",
    },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    keys = {
      { "<leader>db", "<cmd>DBUIToggle<CR>", desc = "Toggle DB UI" },
      { "<leader>da", "<cmd>DBUIAddConnection<CR>", desc = "Add DB Connection" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  
  -- Python environment management with improved regexp search
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",  -- Use the latest 2024 version with regexp support
    cmd = "VenvSelect",
    keys = {
      { "<leader>yv", "<cmd>VenvSelect<CR>", desc = "Select Python venv" },
      { "<leader>yd", "<cmd>VenvSelectCached<CR>", desc = "Select cached venv" },
    },
    opts = {
      name = { "venv", ".venv", "env", ".env" },
      auto_refresh = true,
      search_venv_managers = true,
      search_workspace = true,
      search_patterns = {
        -- Custom search patterns
        { "venv", "env", ".venv", ".env" },                       -- Common venv folder names
        { "*/venv", "*/env", "*/.venv", "*/.env" },               -- Search for venvs one level down
        { "**/venv", "**/env", "**/.venv", "**/.env" },           -- Search for venvs anywhere below
        { "global", "**/*venv*", "**/*env*" },                   -- Match any path with venv/env in the name
      },
      dap_enabled = true,  -- Enable DAP support
      parents = 2,         -- Search 2 levels up for venvs
      path_to_python = "bin/python",  -- Path to the python executable
      change_venv_hooks = {
        function(venv_path)
          -- Update python3_host_prog
          vim.g.python3_host_prog = venv_path .. "/bin/python"
          -- Notify the user
          vim.notify("Activated venv: " .. venv_path, vim.log.levels.INFO, { title = "Python Environment" })
        end,
      },
    },
    init = function()
      -- Setup quick access shortcuts, mapped already in mappings.lua
    end,
  },
  
  -- Code formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>cf", function() require("conform").format() end, desc = "Format document" },
    },
    opts = {
      formatters_by_ft = {
        python = { "isort", "black" },
        go = { "gofmt", "goimports" },
        lua = { "stylua" },
        sql = { "sqlformat" },
        json = { "jq" },
        yaml = { "yamlfmt" },
        dockerfile = { "hadolint" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        c = { "clang_format" },
        cpp = { "clang_format" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
  
  -- Github Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  
  {
    "zbirenbaum/copilot-cmp",
    version = "*", -- Use latest release version to fix deprecation warnings
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      require("copilot_cmp").setup({
        -- Fix deprecated API warnings by using a custom source filter function
        fix_mode = true, -- Use the fixed version of source.is_stopped
      })
    end,
  },
  
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "rose-pine",
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } }, -- Show relative path
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  
  -- Enhanced command-line UI with wilder.nvim
  {
    "gelguy/wilder.nvim",
    event = "CmdlineEnter",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "romgrk/fzy-lua-native",
        build = "make",
      },
    },
    build = ":TSUpdate",
    config = function()
      local wilder = require("wilder")
      wilder.setup({
        modes = { ":", "/", "?" },
        next_key = "<Tab>",
        previous_key = "<S-Tab>",
        accept_key = "<Down>",
        reject_key = "<Up>",
        enable_python = false,  -- Disable Python features
        use_python_remote_plugin = false,  -- Don't use Python remote plugin
      })

      -- Use only Lua-based functionality to avoid Python errors
      -- Create file finder function using Lua
      local file_finder = function(prefix, check_dirname)
        return function(path)
          local base = vim.fn.fnamemodify(path.."x", ":h:r")  -- add a dummy 'x' to handle empty paths
          base = base == "." and "" or base
          base = base..(base == "" and "" or "/")
          
          local cmd = "find "..vim.fn.shellescape(base).." -maxdepth 1 -type f,l"
          if prefix then
            cmd = cmd.." -name "..vim.fn.shellescape(prefix.."*")
          end
          cmd = cmd.." 2>/dev/null"
          
          local handle = io.popen(cmd)
          if not handle then return {} end
          
          local result = handle:read("*a")
          handle:close()
          
          local names = {}
          for name in string.gmatch(result, "[^\n]+") do
            table.insert(names, name)
          end
          
          return names
        end
      end
      
      -- Create custom file completion using Lua only
      local file_completion = {
        expand = function(arg)
          if arg == nil then
            return ""
          end
          return vim.fn.fnamemodify(arg, ":p")
        end,
        
        dict = file_finder(),
      }

      -- Use native Lua-based fuzzy search and completion
      wilder.set_option("pipeline", {
        wilder.branch(
          -- Use lua_fzy_filter which doesn't rely on Python
          wilder.cmdline_pipeline({
            language = "vim",
            fuzzy = 1,
            fuzzy_filter = wilder.lua_fzy_filter(),
            debounce = 10,
          }),
          -- Use Lua-based vim_search_pipeline for search
          wilder.vim_search_pipeline()
        )
      })

      -- Rose Pine color scheme for wilder.nvim
      local rose_pine_colors = {
        bg = "#1a1d23",
        fg = "#aeaebf",
        accent = "#dca561",
        selected = "#2a2b33",
        border = "#3b3f4e",
        gray = "#565f89",
        error = "#f7768e",
        warning = "#e0af68",
        info = "#7dcfff",
        hint = "#9ece6a",
      }

      -- Create highlight groups for wilder
      local popupmenu_renderer = wilder.popupmenu_renderer(
        wilder.popupmenu_border_theme({
          highlights = {
            default = "Pmenu",
            border = "WilderBorder",
            accent = "WilderAccent",
            selected = "PmenuSel",
            error = "WilderError",
          },
          border = "rounded",
          left = {
            " ",
            wilder.popupmenu_devicons(),
            wilder.popupmenu_buffer_flags({
              flags = " a + ",
              icons = { ["+"] = "", ["a"] = "", ["h"] = "" },
            }),
          },
          right = {
            " ",
            wilder.popupmenu_scrollbar({
              thumb_char = '┃',
              minheight = 1,
            }),
          },
          empty_message = wilder.popupmenu_empty_message({
            message = " No matches ",
          }),
          min_width = "15%",
          min_height = "10%",
          max_height = "30%",
          reverse = 0,
        })
      )

      -- Create highlight commands for wilder
      vim.cmd(string.format("hi WilderBorder guifg=%s guibg=%s", rose_pine_colors.border, rose_pine_colors.bg))
      vim.cmd(string.format("hi WilderAccent guifg=%s guibg=%s", rose_pine_colors.accent, rose_pine_colors.bg))
      vim.cmd(string.format("hi WilderError guifg=%s guibg=%s", rose_pine_colors.error, rose_pine_colors.bg))
      vim.cmd(string.format("hi WilderScrollbar guifg=%s", rose_pine_colors.accent))
     
      -- Set the renderer
      wilder.set_option('renderer', popupmenu_renderer)
    end,
  },
  
  -- Comment toggling
  {
    "numToStr/Comment.nvim",
    lazy = false,
    config = true,
  },
  
  -- Colors for color codes
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufReadPre",
    config = true,
  },
  
  -- Undotree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Toggle Undotree" },
    },
    config = function()
      vim.g.undotree_WindowLayout = 3  -- Layout 3 puts tree on the right, diff on the bottom
      vim.g.undotree_SplitWidth = 25   -- Reduced from 30 to 25
      vim.g.undotree_DiffpanelHeight = 8  -- Reduced from 10 to 8
      vim.g.undotree_SetFocusWhenToggle = 0  -- Don't focus undotree when opened (stay in the file)
      vim.g.undotree_ShortIndicators = 1  -- Use short indicators
      vim.g.undotree_TreeNodeShape = '●'  -- Use a smaller icon for nodes
      vim.g.undotree_TreeVertShape = '│'  -- Use simpler vertical lines
      vim.g.undotree_TreeSplitShape = '╱'  -- Use simpler split shapes
      vim.g.undotree_TreeReturnShape = '╲'  -- Use simpler return shapes
      vim.g.undotree_DiffCommand = "diff"  -- Use standard diff command
      vim.g.undotree_RelativeTimestamp = 1  -- Use relative timestamps
      vim.g.undotree_HighlightChangedText = 1  -- Highlight changed text
      vim.g.undotree_HighlightChangedWithSign = 1  -- Show signs for changed text
    end,
  },
  
  -- DevDocs integration for programming language documentation
  {
    "luckasRanarison/nvim-devdocs",
    event = "VeryLazy", 
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local status_ok, devdocs = pcall(require, "nvim-devdocs")
      if not status_ok then
        vim.notify("Could not load nvim-devdocs plugin", vim.log.levels.ERROR)
        return
      end
      
      -- Setup DevDocs
      devdocs.setup({
        dir_path = vim.fn.stdpath("data") .. "/devdocs", -- documentation storage path
        telescope = {
          width = 0.7, -- Simpler, more focused UI
          height = 0.5, -- Less intrusive
          previewer_width = 0.5, -- More balanced preview
        },
        float_win = {
          relative = "editor",
          height = 0.7, -- More compact floating window
          width = 0.7,
          border = "rounded",
          title = "DevDocs",
          title_pos = "center",
        },
        wrap = true, -- Wrap content in devdocs buffer
        after_open = function(bufnr)
          -- Set buffer options for better reading experience
          vim.api.nvim_buf_set_option(bufnr, "foldenable", false)
          vim.api.nvim_buf_set_option(bufnr, "spell", false)
          
          -- Add keymappings specific to documentation buffer
          vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', ':DevdocsOpenFloat<CR>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', '/', '/', { noremap = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', 'n', 'n', { noremap = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', 'N', 'N', { noremap = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-s>', ':DevdocsOpen<CR>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-v>', ':DevdocsOpen<CR>', { noremap = true, silent = true })
          vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-t>', ':DevdocsOpen<CR>', { noremap = true, silent = true })
          -- Notify user about search capabilities
          vim.notify("[DevDocs] '/' to search, <C-s>/<C-v>/<C-t> to open, 'q' to close.", vim.log.levels.INFO)
        end,
        ensure_installed = {
          -- Automatically install these documentations on startup
          "python~3.11",  -- Specific Python version
          "javascript",
          "typescript",
          "bash",
          "git",
          "docker",
          "sql",
          "scikit_learn",  -- Machine learning library
          "numpy~1.24",    -- Data manipulation
          "pandas~1",      -- Data analysis
        },
        mappings = {
          open_in_split = "<C-s>",
          open_in_vsplit = "<C-v>",
          open_in_tab = "<C-t>",
        },
      })
      
      -- Create command aliases for DevDocs to ensure compatibility
      vim.api.nvim_create_user_command("DevdocsFetch", function()
        vim.notify("Fetching documentation index...", vim.log.levels.INFO)
        if devdocs.update_metadata then
          devdocs.update_metadata()
        else
          vim.notify("DevDocs: update_metadata() not available in this version", vim.log.levels.WARN)
        end
      end, {})
      
      vim.api.nvim_create_user_command("DevdocsInstall", function(opts)
        if opts.args and opts.args ~= "" then
          vim.notify("Installing documentation for " .. opts.args, vim.log.levels.INFO)
          devdocs.install(opts.args)
        else
          vim.notify("Please specify a documentation to install", vim.log.levels.ERROR)
        end
      end, { nargs = "?" })
      
      -- Fix DevdocsOpen: Don't create a circular reference
      vim.api.nvim_create_user_command("DevdocsOpenCmd", function(opts)
        local success, err = pcall(function()
          if opts.args and opts.args ~= "" then
            -- Call the native command directly without our wrapper
            vim.cmd("DevdocsOpen " .. vim.fn.shellescape(opts.args))
          else
            vim.cmd("DevdocsOpen")
          end
        end)
        
        if not success then
          vim.notify("DevDocs error: " .. tostring(err), vim.log.levels.ERROR)
        end
      end, { nargs = "?" })
      
      -- Fix DevdocsOpenFloat: Don't create a circular reference
      vim.api.nvim_create_user_command("DevdocsOpenFloatCmd", function(opts)
        local success, err = pcall(function()
          if opts.args and opts.args ~= "" then
            -- Call the native command directly without our wrapper
            vim.cmd("DevdocsOpenFloat " .. vim.fn.shellescape(opts.args))
          else
            vim.cmd("DevdocsOpenFloat")
          end
        end)
        
        if not success then
          vim.notify("DevDocs error: " .. tostring(err), vim.log.levels.ERROR)
        end
      end, { nargs = "?" })
      
      vim.api.nvim_create_user_command("DevdocsSearch", function()
        if devdocs.search then
          devdocs.search()
        else
          -- Fallback if search function is not available
          vim.notify("Search function not available in this version", vim.log.levels.WARN)
          -- Use our fixed command
          vim.cmd("DevdocsOpenCmd")
        end
      end, {})
    end,
  },
  
  -- Alpha dashboard for a beautiful welcome screen
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("dashboard").setup()
    end,
  },
}
