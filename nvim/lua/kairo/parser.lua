-- Builds the tree-sitter parser from the grammar sources and attaches it.
--
--   grammar   path to tree-sitter-kairo (default: ../tree-sitter-kairo, then ./tree-sitter-kairo)
--   cc        C compiler (default: $CC, then cc / gcc / clang / zig)
-- both set through require("kairo").setup{} (or vim.g.kairo_grammar / kairo_cc)

local M = {}

local uv = vim.uv
local building = false
local loaded = false
local warned = false

local function notify(msg, level)
  vim.schedule(function()
    vim.notify("kairo: " .. msg, level or vim.log.levels.INFO)
  end)
end

local function mtime(path)
  local st = uv.fs_stat(path)
  return st and st.mtime.sec or nil
end

local function plugin_root()
  local file = debug.getinfo(1, "S").source:sub(2)
  return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(file)))
end

function M.grammar_dir()
  local root = plugin_root()
  local cfg = require("kairo").config()
  local candidates = {
    cfg.grammar and vim.fs.normalize(cfg.grammar) or nil,
    vim.fs.joinpath(vim.fs.dirname(root), "tree-sitter-kairo"),
    vim.fs.joinpath(root, "tree-sitter-kairo"),
  }
  for i = 1, 3 do
    local dir = candidates[i]
    if dir and uv.fs_stat(vim.fs.joinpath(dir, "src", "scanner.c")) then
      return dir
    end
  end
end

function M.output()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "parser", "kairo.so")
end

-- Registers the parser with Neovim. Prefers the one built here, then
-- whatever is on the runtimepath.
function M.load()
  if loaded then
    return true
  end
  local out = M.output()
  if uv.fs_stat(out) then
    loaded = pcall(vim.treesitter.language.add, "kairo", { path = out })
  end
  if not loaded then
    local ok, added = pcall(vim.treesitter.language.add, "kairo")
    loaded = ok and added == true
  end
  return loaded
end

-- The built parser is older than the grammar it was built from.
function M.stale()
  local dir = M.grammar_dir()
  local built = mtime(M.output())
  if not dir or not built then
    return false
  end
  for _, name in ipairs({ "parser.c", "scanner.c" }) do
    local src = mtime(vim.fs.joinpath(dir, "src", name))
    if src and src > built then
      return true
    end
  end
  return false
end

local function compiler()
  local names = { require("kairo").config().cc, vim.env.CC, "cc", "gcc", "clang", "zig" }
  for i = 1, 6 do
    local name = names[i]
    if name and name ~= "" and vim.fn.executable(name) == 1 then
      return name
    end
  end
end

local function start_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "kairo" then
      pcall(vim.treesitter.start, buf, "kairo")
    end
  end
end

---@param opts? { sync?: boolean }
function M.build(opts)
  opts = opts or {}
  if building then
    return
  end

  local dir = M.grammar_dir()
  if not dir then
    notify("tree-sitter-kairo not found; set grammar in require('kairo').setup{}", vim.log.levels.ERROR)
    return
  end
  local cc = compiler()
  if not cc then
    notify("no C compiler found; set cc in require('kairo').setup{}", vim.log.levels.ERROR)
    return
  end

  local src = vim.fs.joinpath(dir, "src")
  local out = M.output()
  local tmp = out .. ".tmp"
  local reload = loaded
  vim.fn.mkdir(vim.fs.dirname(out), "p")

  local steps = {}
  if not uv.fs_stat(vim.fs.joinpath(src, "parser.c")) then
    if vim.fn.executable("tree-sitter") ~= 1 then
      notify("src/parser.c is missing and the tree-sitter CLI is not on PATH", vim.log.levels.ERROR)
      return
    end
    steps[#steps + 1] = { "tree-sitter", "generate" }
  end
  local compile = cc == "zig" and { "zig", "cc" } or { cc }
  vim.list_extend(compile, { "-O2", "-std=c11", "-shared" })
  if vim.fn.has("win32") == 0 then
    compile[#compile + 1] = "-fPIC"
  end
  vim.list_extend(compile, {
    "-I", src,
    vim.fs.joinpath(src, "parser.c"),
    vim.fs.joinpath(src, "scanner.c"),
    "-o", tmp,
  })
  steps[#steps + 1] = compile

  local function finish(err)
    building = false
    if err then
      uv.fs_unlink(tmp)
      notify("parser build failed\n" .. err, vim.log.levels.ERROR)
      return
    end
    local ok, rename_err = uv.fs_rename(tmp, out)
    if not ok then
      notify("could not install parser: " .. tostring(rename_err), vim.log.levels.ERROR)
      return
    end
    if reload then
      notify("parser rebuilt; restart Neovim to load it")
    else
      notify("parser built")
      vim.schedule(function()
        if M.load() then
          start_buffers()
        end
      end)
    end
  end

  local function run(i)
    local cmd = steps[i]
    if not cmd then
      return finish()
    end
    local function done(res)
      if res.code ~= 0 then
        return finish(table.concat(cmd, " ") .. "\n" .. (res.stderr or ""))
      end
      run(i + 1)
    end
    if opts.sync then
      done(vim.system(cmd, { cwd = dir, text = true }):wait())
    else
      vim.system(cmd, { cwd = dir, text = true }, done)
    end
  end

  building = true
  if not opts.sync then
    notify("building parser with " .. cc .. " ...")
  end
  run(1)
end

-- Start highlighting for a buffer, building the parser first when needed.
function M.attach(buf)
  if M.load() then
    pcall(vim.treesitter.start, buf, "kairo")
    if M.stale() then
      M.build()
    end
    return
  end
  if M.grammar_dir() then
    M.build()
  elseif not warned then
    warned = true
    notify("no parser installed; set grammar in require('kairo').setup{} and run :KairoBuildParser", vim.log.levels.WARN)
  end
end

return M
