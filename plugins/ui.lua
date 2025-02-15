-- ui.lua
-- Configuration for 'folke/snacks.nvim'
-- For more details, see: https://www.lazyvim.org/plugins/ui#snacksnvim

return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          -- Dashboard header logo
          header = [[
  ██████  ██    ██ ███████ ████████ ██████  ███████ ██    ██
  ██   ██ ██    ██ ██         ██    ██   ██ ██      ██    ██
  ██████  ██    ██ ███████    ██    ██   ██ █████   ██    ██
  ██   ██ ██    ██      ██    ██    ██   ██ ██       ██  ██
██   ██  ██████  ███████    ██    ██████  ███████   ████

🚀 Rust Powered Dev Environment 🚀
          ]],
          -- Dashboard keys configuration
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            {
              icon = "🔍", -- Find File
              key = "f",
              desc = "Find File",
              action = ":lua Snacks.dashboard.pick('files')",
            },
            {
              icon = "📝", -- New File
              key = "n",
              desc = "New File",
              action = ":ene | startinsert",
            },
            {
              icon = "🔎", -- Find Text
              key = "g",
              desc = "Find Text",
              action = ":lua Snacks.dashboard.pick('live_grep')",
            },
            {
              icon = "🕒", -- Recent Files
              key = "r",
              desc = "Recent Files",
              action = ":lua Snacks.dashboard.pick('oldfiles')",
            },
            {
              icon = "⚙️", -- Config
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            {
              icon = "♻️", -- Restore Session
              key = "s",
              desc = "Restore Session",
              section = "session",
            },
            {
              icon = "✨", -- Lazy Extras
              key = "x",
              desc = "Lazy Extras",
              action = ":LazyExtras",
            },
            {
              icon = "🚀", -- Lazy
              key = "l",
              desc = "Lazy",
              action = ":Lazy",
            },
            {
              icon = "❌", -- Quit
              key = "q",
              desc = "Quit",
              action = ":qa",
            },
          },
        },
      },
    },
  },
}