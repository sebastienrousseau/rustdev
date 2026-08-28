-- langdev common — intentionally disabled plugins
-- SPDX-License-Identifier: MIT
--
-- Mason (and mason-lspconfig) are disabled ON PURPOSE. In langdev,
-- language servers, formatters and debug adapters are installed at
-- BUILD time by each image's toolchain stage (apk / rustup / uv / pip)
-- and configured directly via nvim-lspconfig in plugins/lang.lua.
--
-- Benefits: no network required on first launch, fully reproducible,
-- smaller runtime, and no "download an LSP into an ephemeral container"
-- surprise. This resolves the historical contradiction where Mason was
-- disabled but still referenced by the LSP config.
return {
  { "williamboman/mason.nvim", enabled = false },
  { "williamboman/mason-lspconfig.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
}
