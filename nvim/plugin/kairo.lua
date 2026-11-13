if vim.g.loaded_kairo then
  return
end
vim.g.loaded_kairo = true

require("kairo").activate()
