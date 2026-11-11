-- `.k` is claimed by kwt in Neovim's builtin table; this takes it over.
vim.filetype.add({
  extension = {
    k = "kairo",
    kairo = "kairo",
    kh = "kairo",
    kairoh = "kairo",
  },
})
