-- :checkhealth kairo
local M = {}

function M.check()
  local h = vim.health
  h.start("kairo")

  if vim.fn.has("nvim-0.11") == 1 then
    h.ok("Neovim " .. tostring(vim.version()))
  else
    h.error("Neovim 0.11 or newer is required (vim.lsp.config / vim.lsp.enable)")
  end

  local cfg = require("kairo").config()
  if not cfg.lsp then
    h.info("the language server is turned off (lsp = false)")
  end
  local exe = cfg.kals.path
  if vim.fn.executable(exe) == 1 then
    local res = vim.system({ exe, "--version" }, { text = true }):wait(5000)
    local line = vim.split((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true })[1]
    h.ok(("`%s` found: %s"):format(vim.fn.exepath(exe), line or "version not reported"))
  else
    h.error(("`%s` is not executable"):format(exe), {
      "Install the Kairo toolchain: https://kairolang.org/docs/install/",
      "or set kals = { path = '/path/to/kals' } in require('kairo').setup{}",
    })
  end
  if vim.lsp.config and vim.lsp.config.kals then
    h.ok("vim.lsp.config.kals is registered")
  elseif cfg.lsp and vim.fn.executable(exe) == 1 then
    h.warn("vim.lsp.config.kals is not registered; call require('kairo').setup() or check the plugin is on the runtimepath")
  end

  local parser = require("kairo.parser")
  local out = parser.output()
  if vim.uv.fs_stat(out) then
    h.ok("parser built: " .. out)
    if parser.stale() then
      h.warn("the parser is older than the grammar sources", { "Run :KairoBuildParser, then restart Neovim" })
    end
  elseif pcall(vim.treesitter.language.add, "kairo") then
    h.ok("a `kairo` parser is on the runtimepath")
  else
    h.warn("no parser built yet", { "It is built when the first Kairo file is opened, or run :KairoBuildParser" })
  end
  local grammar = parser.grammar_dir()
  if grammar then
    h.ok("grammar sources: " .. grammar)
  else
    h.warn("tree-sitter-kairo sources not found", { "Set grammar = '/path/to/tree-sitter-kairo' in require('kairo').setup{}" })
  end

  local cc
  for _, name in ipairs({ cfg.cc, vim.env.CC, "cc", "gcc", "clang", "zig" }) do
    if name and name ~= "" and vim.fn.executable(name) == 1 then
      cc = name
      break
    end
  end
  if cc then
    h.ok("C compiler: " .. cc)
  else
    h.error("no C compiler found (cc, gcc, clang or zig)", { "Needed to build the parser; or set cc = '...' in setup" })
  end
  if vim.fn.executable("tree-sitter") == 1 then
    h.ok("tree-sitter CLI found (only needed to regenerate src/parser.c)")
  else
    h.info("tree-sitter CLI not found (only needed when src/parser.c is missing)")
  end
end

return M
