-- Starts kals, the Kairo language server, for Kairo buffers.
--
--   vim.g.kairo_lsp       false to leave the server alone (default: on)
--   vim.g.kairo_kals      the binary (default: `kals` on PATH)
--
-- Neovim 0.11+ (vim.lsp.config / vim.lsp.enable).

local M = {}

local function command()
  local exe = vim.g.kairo_kals
  if exe == nil or exe == "" then
    exe = "kals"
  end
  return exe
end

-- Semantic-token marks only Kairo has. A call that picks one of several
-- overloads, or runs a user-defined operator, is underlined; one that
-- dispatches through `where` guards is underlined and italic. `default = true`
-- so a colorscheme or the user's own :highlight wins.
local function highlights()
  local set = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
  set("@lsp.mod.overloaded.kairo", { underline = true })
  set("@lsp.mod.dispatched.kairo", { underline = true, italic = true })
  set("@lsp.type.selfKeyword.kairo", { link = "@variable.builtin" })
  set("@lsp.type.builtinType.kairo", { link = "@type.builtin" })
  set("@lsp.type.typeAlias.kairo", { link = "@type.definition" })
  set("@lsp.type.union.kairo", { link = "@type" })
  set("@lsp.type.enumMember.kairo", { link = "@constant" })
end

function M.setup()
  if vim.g.kairo_lsp == false then
    return
  end
  if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
    return -- older Neovim: highlighting only
  end
  local exe = command()
  if vim.fn.executable(exe) ~= 1 then
    return -- no toolchain on PATH; the plugin is still a syntax plugin
  end

  highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("kairo_lsp_hl", { clear = true }),
    callback = highlights,
  })

  vim.lsp.config("kals", {
    cmd = { exe },
    filetypes = { "kairo" },
    root_markers = { "kairo_compile.json", ".git" },
  })
  vim.lsp.enable("kals")

  -- Formatting is kfmt's, through the server.
  vim.api.nvim_create_user_command("KairoFormat", function()
    vim.lsp.buf.format({ name = "kals" })
  end, { desc = "Format the buffer with kfmt (through kals)" })
end

return M
