vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- Set shortcut to change to GitHub directory
vim.api.nvim_set_keymap('n', '<leader>gh', ':cd /Users/offbeat/Documents/GitHub<CR>', { noremap = true, silent = true })

-- Add pane navigation shortcuts
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })

-- Add shortcut to select all code
vim.api.nvim_set_keymap('n', '<leader>a', 'ggVG', { noremap = true, silent = true })

-- Add shortcut to close current pane
vim.api.nvim_set_keymap('n', '<leader>x', ':quit<CR>', { noremap = true, silent = true })

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

  -- Add pyright for Python LSP and virtual environment support
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.pyright.setup {
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace"
            },
          },
        },
      }
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
        debounce_delay = 10,
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

-- Function to find and activate .venv in the project root
function FindAndActivateVenv()
  local function has_venv(dir)
    return vim.fn.isdirectory(dir .. "/.venv") == 1
  end

  local current_dir = vim.fn.expand("%:p:h")
  local venv_dir = current_dir

  -- Search for .venv in current and parent directories
  while not has_venv(venv_dir) do
    local parent = vim.fn.fnamemodify(venv_dir, ":h")
    if parent == venv_dir then
      -- Reached root directory, .venv not found
      return nil
    end
    venv_dir = parent
  end

  local venv_path = venv_dir .. "/.venv"
  vim.fn.setenv("VIRTUAL_ENV", venv_path)
  vim.fn.setenv("PATH", venv_path .. "/bin:" .. vim.fn.getenv("PATH"))
  -- Removed the print statement to avoid the "Press ENTER" prompt
  return venv_path
end

-- Automatically activate .venv when opening a Python file
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    FindAndActivateVenv()
  end
})

-- Function to run the current Python file
function RunPythonFile()
  -- Save the current file
  vim.cmd('write')
  
  -- Get the path of the current file
  local file_path = vim.fn.expand('%:p')
  
  -- Ensure the virtual environment is activated
  local venv = FindAndActivateVenv()
  local python_cmd = venv and (venv .. "/bin/python") or "python"
  
  -- Open a new split window, run the Python file, and enter insert mode
  vim.cmd('vsplit | terminal ' .. python_cmd .. ' ' .. vim.fn.shellescape(file_path))
  vim.cmd('startinsert')
end

-- Set shortcut to run the current Python file
vim.api.nvim_set_keymap('n', '<leader>r', ':lua RunPythonFile()<CR>', { noremap = true, silent = true })

-- Log Python and virtual environment information
vim.api.nvim_create_user_command("LogPythonInfo", function()
  print("Current working directory: " .. vim.fn.getcwd())
  print("Python path: " .. vim.fn.exepath("python"))
  local venv = os.getenv("VIRTUAL_ENV")
  if venv then
    print("Active virtual environment: " .. venv)
  else
    print("No active virtual environment")
  end
end, {})

-- Diagnostic function for nvim-tree
vim.api.nvim_create_user_command("DiagnoseNvimTree", function()
  local nvim_tree = require("nvim-tree")
  print("Nvim-tree version: " .. (nvim_tree.version and nvim_tree.version() or "Unknown"))
  print("Current working directory: " .. vim.fn.getcwd())
  print("Filesystem watchers enabled: " .. tostring(nvim_tree.config.filesystem_watchers.enable))
  print("Debounce delay: " .. nvim_tree.config.filesystem_watchers.debounce_delay)
  print("Ignored directories: " .. vim.inspect(nvim_tree.config.filesystem_watchers.ignore_dirs))
end, {})
