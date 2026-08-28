-- langdev common — UI + Treesitter core (language-agnostic)
-- SPDX-License-Identifier: MIT
return {
  -- Colorscheme (ships with LazyVim; pinned by lazy-lock.json).
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },

  -- Treesitter: only the parsers every image needs. Language repos
  -- append their own grammar in plugins/lang.lua via opts.ensure_installed.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "dockerfile",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "regex",
        "toml",
        "yaml",
      },
      -- Parsers are compiled at build time; do not auto-install at runtime.
      auto_install = false,
    },
  },
}
