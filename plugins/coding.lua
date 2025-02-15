-- coding.lua
-- This configuration file sets up coding-related plugins:
-- 1. Autocompletion with nvim-cmp, including custom keybindings.
-- 2. Treesitter with enhanced syntax highlighting and parsing for Rust and TOML.
-- 3. Rust-specific tools and LSP configuration

return {
  -----------------------------------------------------------------------------
  -- Autocompletion with nvim-cmp
  -----------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      -- Merge custom keybindings with the existing mappings.
      opts.mapping = vim.tbl_deep_extend("force", opts.mapping, {
        -- Use Ctrl-j to select the next completion item.
        ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        -- Use Ctrl-k to select the previous completion item.
        ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- Treesitter for enhanced syntax highlighting and parsing.
  -----------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Ensure Treesitter is set up to parse Rust and TOML files.
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "rust", "toml" })
      end
    end,
  },

  -----------------------------------------------------------------------------
  -- Rust Tools Configuration
  -----------------------------------------------------------------------------
  {
    "simrat39/rust-tools.nvim",
    ft = "rust",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local rt = require("rust-tools")
      rt.setup({
        server = {
          on_attach = function(_, bufnr)
            -- Hover actions
            vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
            -- Code action groups
            vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
          end,
          settings = {
            ["rust-analyzer"] = {
              checkOnSave = {
                command = "clippy",
              },
              cargo = {
                allFeatures = true,
              },
              procMacro = {
                enable = true,
              },
            },
          },
        },
      })
    end,
  },

  -----------------------------------------------------------------------------
  -- Mason for LSP Server Management
  -----------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
      },
    },
  },

  -----------------------------------------------------------------------------
  -- Autopairs for Automatic Insertion of Matching Brackets and Quotes
  -----------------------------------------------------------------------------
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

  ------------------------------------------------------------------------------
  -- Surround: Easily Modify Surrounding Characters (Quotes, Brackets, etc.)
  ------------------------------------------------------------------------------
  {
    "kylechui/nvim-surround",
    config = function()
      require("nvim-surround").setup({})
    end,
  },

  ------------------------------------------------------------------------------
  -- Commenting Utility: Toggle Comments Easily in Normal and Visual Modes
  ------------------------------------------------------------------------------
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({})
    end,
  },
}