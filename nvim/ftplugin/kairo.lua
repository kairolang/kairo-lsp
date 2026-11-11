if vim.b.did_ftplugin then
  return
end
vim.b.did_ftplugin = 1

vim.bo.commentstring = "// %s"
vim.bo.comments = ":///<,://<,:///,://,s1:/*,mb:*,ex:*/"
vim.opt_local.formatoptions:remove("t")
vim.opt_local.formatoptions:append("crqj")
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

vim.b.undo_ftplugin = "setl cms< com< fo< sw< sts< et<"

require("kairo.parser").attach(vim.api.nvim_get_current_buf())
