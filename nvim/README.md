# Kairo for Neovim

Kairo language support for Neovim: the `kals` language server and syntax highlighting built on `tree-sitter-kairo`. `:help kairo` has the full reference.

Requires Neovim 0.11+, a C compiler (`cc`, `gcc`, `clang` or `zig`) and the Kairo toolchain (`kals`, `kfmt`) on `PATH`: <https://kairolang.org/docs/install/>.

## Install

The plugin is the `nvim/` directory of this repository; the grammar it builds is its sibling `tree-sitter-kairo/`. Plugin managers clone the whole repository, so `nvim/` is put on the runtimepath by hand.

lazy.nvim:

```lua
{
  "kairolang/kairo-lsp",
  name = "kairo",
  config = function(plugin)
    vim.opt.rtp:append(plugin.dir .. "/nvim")
    require("kairo").setup({})
  end,
}
```

packer.nvim:

```lua
use({ "kairolang/kairo-lsp", rtp = "nvim", config = function() require("kairo").setup({}) end })
```

vim.pack:

```lua
vim.pack.add({ "https://github.com/kairolang/kairo-lsp" })
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site/pack/core/opt/kairo-lsp/nvim")
require("kairo").setup({})
```

Manual:

```lua
vim.opt.rtp:prepend("~/kairo-lsp/nvim")
```

then `:helptags ALL` once for `:help kairo`. `setup()` is optional: on the runtimepath the plugin works with its defaults. If `nvim/` becomes a repository of its own, the plugin is that repository's root and the `rtp` lines go away; the parser then builds from a `tree-sitter-kairo/` directory inside it, or from `grammar = "..."`.

## Setup

```lua
require("kairo").setup({
  kals = { path = "kals", args = {} },
  lsp = true,                           -- false: never start the server
  root_markers = { "kairo_compile.json", ".git" },
  init_options = {                      -- same names and defaults as the VS Code settings
    liveCheck = true,
    debounceMs = 150,
    syntaxDebounceMs = 100,
    maxWorkers = 2,
    highlightPanics = false,
  },
  grammar = nil,                        -- path to tree-sitter-kairo
  cc = nil,                             -- C compiler for the parser
})
```

| Option | VS Code setting |
|---|---|
| `kals.path`, `kals.args` | `kairo.kals.path`, `kairo.kals.args` |
| `init_options.liveCheck` | `kairo.kals.liveCheck` |
| `init_options.debounceMs`, `syntaxDebounceMs`, `maxWorkers` | `kairo.kals.debounceMs`, `syntaxDebounceMs`, `maxWorkers` |
| `init_options.highlightPanics` | `kairo.kals.highlightPanics` |

Every client uses the server's own option names (`liveCheck`, `debounceMs`, `syntaxDebounceMs`, `maxWorkers`, `highlightPanics`); VS Code spells them `kairo.kals.<name>`.

Server options are read when the server starts: `:LspRestart` after changing them. The older `vim.g.kairo_lsp`, `kairo_kals`, `kairo_highlight_panics`, `kairo_grammar` and `kairo_cc` still work; `setup()` wins over them.

## Parser

The parser is compiled the first time a Kairo file is opened and installed to `stdpath("data")/site/parser/kairo.so`. It is rebuilt when `src/parser.c` or `src/scanner.c` is newer than the installed build; a rebuilt parser is picked up on the next start. If `src/parser.c` is missing, `tree-sitter generate` is run first. `:KairoBuildParser` forces a rebuild.

## What it sets up

- filetype `kairo` for `.k`, `.kairo`, `.kh`, `.kairoh`
- `queries/kairo/highlights.scm` using Neovim capture names; `injections.scm` marks comments (the `comment` parser, when installed). `inline "asm"` bodies are not injected.
- `commentstring`, `comments`, 4-space indentation
- the language server (below), `:KairoFormat`, `:checkhealth kairo`

## Language server

With `kals` on `PATH` it is started for every Kairo buffer (`vim.lsp.config("kals", ...)` and `vim.lsp.enable("kals")`): diagnostics, completion, hover, go to definition, references, rename, signature help, inlay hints, semantic highlighting. When `kals` is not executable, a warning with the install link appears when the first Kairo file opens.

Highlight groups Kairo adds (all overridable, set with `default = true`):

| Group | Default | On |
|---|---|---|
| `@lsp.mod.overloaded.kairo` | underline | a call that picks one of several overloads, or a user-defined operator |
| `@lsp.mod.dispatched.kairo` | underline, italic | a call that dispatches through `where` guards |
| `@lsp.mod.extension.kairo`, `@lsp.mod.ffi.kairo` | italic | extension calls; calls into C/C++ |
| `@lsp.mod.unsafe.kairo` | bold | unsafe uses |
| `@lsp.typemod.operator.mutates.kairo` | bold | the `&` a call may write through |
| `@lsp.mod.deprecated.kairo` | strikethrough | deprecated uses |
| `@lsp.mod.panics.kairo` | dotted underline | calls that can panic (needs `highlightPanics`) |
| `@lsp.type.macro.kairo` | amber | macro names and their `!` |
| `KairoAmpInout` / `KairoAmpPointer` / `KairoAmpUnsafe` / `KairoAmpUnsafeConst` / `KairoAmpConst` | green / bold / purple / purple italic / grey-blue, all bold | the `&` of a call argument, by the parameter it binds to |

Projects are described by `kairo_compile.json`; see <https://kairolang.org/docs/toolchain/kals/>.

## Publishing (maintainer)

Users install from `kairolang/kairo-lsp` as above; tag a release there (`git tag nvim-v0.1.0 && git push origin nvim-v0.1.0`) and users pin it with lazy.nvim's `tag` or `version`. Plugin managers see the repository's tags, not subdirectory ones, so tag the whole repository.

The plugin carries its own copy of the generated parser in `nvim/tree-sitter-kairo/src/`, so `nvim/` works alone. The sibling `../tree-sitter-kairo` wins when it is present. After `tree-sitter generate`, run `python3 tree-sitter-kairo/scripts/sync_nvim.py` (`--check` reports a stale copy). A `kairo.nvim` mirror whose root is the plugin is then the contents of `nvim/` and nothing else: `git subtree split --prefix=nvim`.
