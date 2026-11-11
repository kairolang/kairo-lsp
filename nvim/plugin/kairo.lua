if vim.g.loaded_kairo then
  return
end
vim.g.loaded_kairo = true

vim.api.nvim_create_user_command("KairoBuildParser", function()
  require("kairo.parser").build()
end, { desc = "Compile the Kairo tree-sitter parser" })

-- The language server, when the toolchain is on PATH (lua/kairo/lsp.lua).
require("kairo.lsp").setup()
