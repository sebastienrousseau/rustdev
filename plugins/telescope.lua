-- telescope.lua
-- Configuration for 'nvim-telescope/telescope.nvim'
-- This configuration sets up a powerful fuzzy finder with custom keybindings and options.

return {
  -----------------------------------------------------------------------------
  -- Telescope Core Configuration
  -----------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { 
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          -- Default configuration
          prompt_prefix = "🔍 ",
          selection_caret = "❯ ",
          path_display = { "truncate" },
          
          -- Key mappings in telescope window
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
            },
          },

          -- Customize file search behavior
          file_ignore_patterns = {
            "target/", -- Ignore Rust build artifacts
            "node_modules/",
            ".git/",
            ".cargo/",
          },

          -- Improve performance
          cache_picker = {
            num_pickers = 5,
            limit_entries = 1000,
          },
        },

        pickers = {
          find_files = {
            hidden = true,
            -- Respect .gitignore
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
          },

          live_grep = {
            -- Additional arguments for live grep
            additional_args = function()
              return { "--hidden" }
            end,
          },

          buffers = {
            show_all_buffers = true,
            sort_lastused = true,
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
            },
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

      -- Load telescope extensions
      telescope.load_extension("fzf")

      -- Global key mappings
      local keymap = vim.keymap.set
      local opts = { noremap = true, silent = true }

      -- Find files
      keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
      -- Live grep
      keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", opts)
      -- Buffers
      keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
      -- Help tags
      keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", opts)
      -- Git files
      keymap("n", "<leader>gf", "<cmd>Telescope git_files<CR>", opts)
      -- Git status
      keymap("n", "<leader>gs", "<cmd>Telescope git_status<CR>", opts)
      -- File browser
      keymap("n", "<leader>fb", "<cmd>Telescope file_browser<CR>", opts)
      -- Grep string under cursor
      keymap("n", "<leader>fs", "<cmd>Telescope grep_string<CR>", opts)
    end,
  },
}