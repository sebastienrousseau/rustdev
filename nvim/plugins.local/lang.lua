-- rustdev — Rust language wiring for Neovim (langdev lang.lua)
-- SPDX-License-Identifier: MIT
--
-- Dropped into the user's chezmoi-managed Neovim config at build time as
-- nvim/plugins.local/lang.lua (auto-imported via the dotfiles' `plugins.local`
-- convention). This is the ONLY nvim change langdev makes — the rest of the
-- editor is the user's own dotfiles.
--
-- rust-analyzer is installed at BUILD time by the toolchain stage (rustup
-- component) and lives on PATH at /opt/langdev/toolchain/cargo/bin, so the LSP
-- needs no Mason/network on first launch and stays reproducible.
--
-- Uses mrcjkb/rustaceanvim (the maintained successor to the archived
-- simrat39/rust-tools.nvim). rustaceanvim configures rust-analyzer itself,
-- so we do NOT also start it via nvim-lspconfig (that would double-attach).
return {
  -- Treesitter grammars for Rust + RON (compiled at build time).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "rust", "ron" })
    end,
  },

  -- rustaceanvim: modern rust-analyzer integration (replaces rust-tools.nvim).
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = { "rust" },
    init = function()
      vim.g.rustaceanvim = {
        server = {
          -- Point at the build-time rust-analyzer on PATH.
          cmd = { "rust-analyzer" },
          default_settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true },
              check = { command = "clippy" },
              procMacro = { enable = true },
            },
          },
          on_attach = function(_, bufnr)
            local map = vim.keymap.set
            map("n", "<leader>a", function()
              vim.cmd.RustLsp("codeAction")
            end, { buffer = bufnr, desc = "Rust code action" })
            map("n", "K", function()
              vim.cmd.RustLsp({ "hover", "actions" })
            end, { buffer = bufnr, desc = "Rust hover actions" })
          end,
        },
      }
    end,
  },
}
