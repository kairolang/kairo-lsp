-- Starts kals, the Kairo language server, for Kairo buffers.
--
--   vim.g.kairo_lsp       false to leave the server alone (default: on)
--   vim.g.kairo_kals      the binary (default: `kals` on PATH)
--   vim.g.kairo_highlight_panics  true to mark calls that can panic (default: off)
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

-- Semantic-token marks only Kairo has, per kals's style table
-- (Compiler/Spec/LanguageServer.md section 5): overloaded = underline;
-- dispatched = underline + italic; extension and C/C++ (ffi) calls = italic;
-- unsafe = bold; the `&` a call may write through (mutates) = bold in the
-- warning colour; deprecated = strikethrough; constants = the enum-member
-- colour; panics = dotted underline (sent only with
-- vim.g.kairo_highlight_panics). `mutable` has no second shade here and is
-- left undrawn. `default = true` so a colorscheme or :highlight wins.
local function highlights()
  local set = function(name, opts)
    opts.default = true
    vim.api.nvim_set_hl(0, name, opts)
  end
  set("@lsp.mod.overloaded.kairo", { underline = true })
  set("@lsp.mod.dispatched.kairo", { underline = true, italic = true })
  set("@lsp.type.selfKeyword.kairo", { link = "@variable.builtin" })
  set("@lsp.mod.extension.kairo", { italic = true })
  set("@lsp.type.builtinType.kairo", { link = "@keyword" })
  set("@lsp.type.typeAlias.kairo", { link = "@type.definition" })
  set("@lsp.type.union.kairo", { link = "@type" })
  set("@lsp.type.enumMember.kairo", { link = "@constant" })
  set("@lsp.mod.ffi.kairo", { italic = true })
  set("@lsp.mod.unsafe.kairo", { bold = true })
  local warn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn", link = false })
  set("@lsp.typemod.operator.mutates.kairo", { bold = true, fg = warn.fg })
  set("@lsp.mod.deprecated.kairo", { strikethrough = true })
  set("@lsp.mod.constant.kairo", { link = "@constant" })
  set("@lsp.mod.panics.kairo", { underdotted = true })
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
    init_options = { highlightPanics = vim.g.kairo_highlight_panics == true },
  })
  vim.lsp.enable("kals")

  -- Formatting is kfmt's, through the server.
  vim.api.nvim_create_user_command("KairoFormat", function()
    vim.lsp.buf.format({ name = "kals" })
  end, { desc = "Format the buffer with kfmt (through kals)" })
end

return M
