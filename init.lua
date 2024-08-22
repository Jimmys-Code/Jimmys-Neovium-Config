vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- Set shortcut to change to GitHub directory
vim.api.nvim_set_keymap('n', '<leader>gh', ':cd /Users/offbeat/Documents/GitHub<CR>', { noremap = true, silent = true })

-- Set shortcut to run the open Python file in a side terminal
vim.api.nvim_set_keymap('n', '<leader>rp', ':vsplit | terminal python %<CR>', { noremap = true, silent = true })

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "options"
    end,
  },

  { import = "plugins" },

  -- Updated venv-selector plugin configuration
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
    config = function()
      require("venv-selector").setup({
        name = {".venv", "venv", "env"},
        auto_refresh = true,
        search_venv_managers = true,
        search_workspace = true,
        search = true,
        path = vim.fn.getcwd(),
        venvwrapper_path = os.getenv("HOME") .. "/.virtualenvs",
        parents = 0,
        enable_debug_output = true,
      })
    end,
    event = "VeryLazy",
    keys = { { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" } },
  },

  -- Add virtualenv plugin
  {
    "jmcantrell/vim-virtualenv",
    config = function()
      -- Set up shortcuts for creating and activating virtual environments
      vim.api.nvim_set_keymap('n', '<leader>vc', ':VirtualEnvCreate<Space>', { noremap = true })
      vim.api.nvim_set_keymap('n', '<leader>va', ':VirtualEnvActivate<Space>', { noremap = true })
      vim.api.nvim_set_keymap('n', '<leader>vd', ':VirtualEnvDeactivate<CR>', { noremap = true })
    end,
  },

  -- Updated nvim-tree configuration
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = {
        dotfiles = false,  -- Show hidden files
        custom = { "^.git$", "^node_modules$", "^.cache$", "^.vscode$", "^.idea$" },
      },
      view = {
        adaptive_size = true,
        side = "left",
      },
      renderer = {
        highlight_git = true,
        icons = {
          show = {
            git = true,
            folder = true,
            file = true,
            folder_arrow = true,
          },
        },
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 500,
      },
      filesystem_watchers = {
        enable = true,
        debounce_delay = 10, -- Reduced from 50 to 10
        ignore_dirs = { "/tmp", "/var", "/home", "/Users" },
      },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      -- Refresh nvim-tree when changing directories
      vim.api.nvim_create_autocmd({ "DirChanged" }, {
        callback = function()
          vim.schedule(function()
            require("nvim-tree.api").tree.reload()
          end)
        end
      })
    end,
  },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

-- Function to create a virtual environment
function CreateVirtualEnv()
  local name = vim.fn.input('Enter name for new virtual environment: ')
  if name ~= "" then
    vim.cmd('!python -m venv ' .. name)
    print('Virtual environment "' .. name .. '" created.')
  else
    print('Virtual environment creation cancelled.')
  end
end

-- Set shortcut to create a new virtual environment
vim.api.nvim_set_keymap('n', '<leader>vn', ':lua CreateVirtualEnv()<CR>', { noremap = true, silent = true })

-- Log virtual environment information
vim.api.nvim_create_user_command("LogVenvInfo", function()
  local venv_selector = require("venv-selector")
  print("Current working directory: " .. vim.fn.getcwd())
  print("Current venv: " .. (venv_selector.get_active_venv() or "None"))
  print("Available venvs:")
  for _, venv in ipairs(venv_selector.get_venvs()) do
    print("  - " .. venv)
  end
  print("Python path: " .. vim.fn.exepath("python"))
end, {})

-- Enable verbose logging for venv-selector
vim.g.venv_selector_debug = true

-- Diagnostic function for nvim-tree
vim.api.nvim_create_user_command("DiagnoseNvimTree", function()
  local nvim_tree = require("nvim-tree")
  print("Nvim-tree version: " .. (nvim_tree.version and nvim_tree.version() or "Unknown"))
  print("Current working directory: " .. vim.fn.getcwd())
  print("Filesystem watchers enabled: " .. tostring(nvim_tree.config.filesystem_watchers.enable))
  print("Debounce delay: " .. nvim_tree.config.filesystem_watchers.debounce_delay)
  print("Ignored directories: " .. vim.inspect(nvim_tree.config.filesystem_watchers.ignore_dirs))
end, {})
