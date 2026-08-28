-- langdev common — editor tooling: fuzzy find + integrated terminal
-- SPDX-License-Identifier: MIT
-- All plugins pinned via lazy-lock.json; branch/version pins here are
-- an additional guard against a breaking major bump.
return {
  -- Telescope: fuzzy finder. Pinned to the stable 0.1.x line.
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        -- Prebuilt at image build time; cmake/make available in toolchain.
        build = "make",
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
    },
    opts = function(_, opts)
      opts.extensions = opts.extensions or {}
      opts.extensions.fzf = {}
      return opts
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- ToggleTerm: integrated terminal. Pinned to a stable major line.
  {
    "akinsho/toggleterm.nvim",
    version = "^2",
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle terminal" },
    },
    opts = {
      open_mapping = [[<c-\>]],
      direction = "float",
      float_opts = { border = "curved" },
      shade_terminals = true,
    },
  },
}
