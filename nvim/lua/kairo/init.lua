-- Kairo for Neovim. `require("kairo").setup{...}` is optional: with defaults
-- the plugin works as soon as it is on the runtimepath (plugin/kairo.lua
-- calls activate()).

local M = {}

---@class kairo.Config
---@field kals { path: string, args: string[] }  server binary and extra arguments
---@field lsp boolean                            false: never start the server
---@field root_markers string[]                  where the project root is
---@field init_options table                     LSP initializationOptions for kals
---@field grammar? string                        tree-sitter-kairo checkout to build from
---@field cc? string                             C compiler for the parser
M.defaults = {
  kals = { path = "kals", args = {} },
  lsp = true,
  root_markers = { "kairo_compile.json", ".git" },
  -- Same names and defaults as the VS Code extension's kairo.kals.* settings.
  init_options = {
    liveCheck = true,
    debounceMs = 150,
    syntaxDebounceMs = 100,
    maxWorkers = 2,
    highlightPanics = false,
  },
}

local user = {}
local activated = false

-- Defaults, then the older vim.g.kairo_* variables, then setup() options.
local function resolve()
  local cfg = vim.deepcopy(M.defaults)
  local g = vim.g
  if g.kairo_lsp == false then
    cfg.lsp = false
  end
  if type(g.kairo_kals) == "string" and g.kairo_kals ~= "" then
    cfg.kals.path = g.kairo_kals
  end
  if g.kairo_highlight_panics ~= nil then
    cfg.init_options.highlightPanics = g.kairo_highlight_panics == true
  end
  cfg.grammar = g.kairo_grammar
  cfg.cc = g.kairo_cc
  return vim.tbl_deep_extend("force", cfg, user)
end

---@return kairo.Config
function M.config()
  return resolve()
end

-- Filetype, commands and the server. Safe to call repeatedly.
function M.activate()
  if activated then
    return
  end
  activated = true
  vim.filetype.add({
    extension = { k = "kairo", kairo = "kairo", kh = "kairo", kairoh = "kairo" },
  })
  vim.api.nvim_create_user_command("KairoBuildParser", function()
    require("kairo.parser").build()
  end, { desc = "Compile the Kairo tree-sitter parser" })
  require("kairo.lsp").setup()
end

---@param opts? table  see M.defaults
function M.setup(opts)
  user = vim.tbl_deep_extend("force", user, opts or {})
  if activated then
    require("kairo.lsp").setup() -- re-registers the config; running servers keep the old one until restarted
  else
    M.activate()
  end
end

return M
