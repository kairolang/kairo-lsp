-- Starts kals, the Kairo language server, for Kairo buffers. Options come
-- from require("kairo").setup{} (see lua/kairo/init.lua and :help kairo).
-- Neovim 0.11+ (vim.lsp.config / vim.lsp.enable).

local M = {}

local warned = false

-- Semantic-token marks only Kairo has, per kals's style table
-- (Compiler/Spec/LanguageServer.md section 5): overloaded = underline;
-- dispatched = underline + italic; extension and C/C++ (ffi) calls = italic;
-- unsafe = bold; the `&` a call may write through (mutates) = bold;
-- deprecated = strikethrough; constants = the enum-member colour; panics =
-- dotted underline (sent only with init_options.highlightPanics); a macro
-- name and its `!` = amber. The `&` of a call argument is
-- coloured by the parameter it binds to (amp_groups below). `mutable` has no
-- second shade here and is left undrawn. `default = true` so a colorscheme
-- or :highlight wins.
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
  set("@lsp.typemod.operator.mutates.kairo", { bold = true })
  set("@lsp.type.macro.kairo", { fg = "#D4900A" })
  set("KairoAmpInout", { bold = true, fg = "#2EA043" })
  set("KairoAmpPointer", { bold = true })
  set("KairoAmpUnsafe", { bold = true, fg = "#B44FD6" })
  set("KairoAmpUnsafeConst", { bold = true, italic = true, fg = "#B44FD6" })
  set("KairoAmpConst", { bold = true, fg = "#7088A8" })
  set("@lsp.mod.deprecated.kairo", { strikethrough = true })
  set("@lsp.mod.constant.kairo", { link = "@constant" })
  set("@lsp.mod.panics.kairo", { underdotted = true })
end

-- The `&` of a call argument, by the parameter it binds to: the first entry
-- whose modifiers the token carries wins. A combination needs its own group:
-- the per-modifier @lsp.typemod groups would each paint the token.
local amp_groups = {
  { { "pointer", "unsafe", "readonly" }, "KairoAmpUnsafeConst" },
  { { "pointer", "unsafe" }, "KairoAmpUnsafe" },
  { { "pointer", "readonly" }, "KairoAmpConst" },
  { { "inout" }, "KairoAmpInout" },
  { { "pointer" }, "KairoAmpPointer" },
}

local function amp_token(args)
  local token = args.data.token
  if token.type ~= "operator" then
    return
  end
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if not client or client.name ~= "kals" then
    return
  end
  for _, entry in ipairs(amp_groups) do
    local all = true
    for _, m in ipairs(entry[1]) do
      if not token.modifiers[m] then
        all = false
        break
      end
    end
    if all then
      vim.lsp.semantic_tokens.highlight_token(token, args.buf, args.data.client_id, entry[2])
      return
    end
  end
end

local function missing(exe)
  if warned then
    return
  end
  warned = true
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("kairo_lsp_missing", { clear = true }),
    pattern = "kairo",
    once = true,
    callback = function()
      vim.notify(
        ("kairo: `%s` is not executable, so there is no language server. Install the Kairo toolchain "
          .. "(https://kairolang.org/docs/install/) or set kals.path in require('kairo').setup{}. "
          .. ":checkhealth kairo has details."):format(exe),
        vim.log.levels.WARN
      )
    end,
  })
end

function M.setup()
  local cfg = require("kairo").config()
  if not cfg.lsp then
    return
  end
  if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
    return -- Neovim older than 0.11: highlighting only
  end
  local exe = cfg.kals.path
  if vim.fn.executable(exe) ~= 1 then
    return missing(exe)
  end

  highlights()
  local hl_group = vim.api.nvim_create_augroup("kairo_lsp_hl", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = hl_group,
    callback = highlights,
  })
  vim.api.nvim_create_autocmd("LspTokenUpdate", {
    group = hl_group,
    callback = amp_token,
  })

  local cmd = { exe }
  vim.list_extend(cmd, cfg.kals.args)
  vim.lsp.config("kals", {
    cmd = cmd,
    filetypes = { "kairo" },
    root_markers = cfg.root_markers,
    init_options = cfg.init_options,
  })
  vim.lsp.enable("kals")

  -- Formatting is kfmt's, through the server.
  vim.api.nvim_create_user_command("KairoFormat", function()
    vim.lsp.buf.format({ name = "kals" })
  end, { desc = "Format the buffer with kfmt (through kals)" })
end

return M
