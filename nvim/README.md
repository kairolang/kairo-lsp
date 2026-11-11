# Kairo for Neovim

Kairo language support for Neovim: the `kals` language server and syntax highlighting built on `tree-sitter-kairo`.

Requires Neovim 0.11+ and a C compiler (`cc`, `gcc`, `clang` or `zig`).

## Install

This directory is the plugin; the grammar sources are its sibling,
`../tree-sitter-kairo`. Clone `kairo-lsp` and put `nvim/` on the runtimepath
from `init.lua`:

```lua
vim.opt.rtp:prepend("~/kairo-lsp/nvim")
```

or with lazy.nvim:

```lua
{ dir = "~/kairo-lsp/nvim" }
```

To build from a different grammar checkout, set `vim.g.kairo_grammar` to its
path before the plugin loads.

## Parser

The parser is compiled the first time a Kairo file is opened and installed to
`stdpath("data")/site/parser/kairo.so`. It is rebuilt when `src/parser.c` or
`src/scanner.c` is newer than the installed build; a rebuilt parser is picked
up on the next start. If `src/parser.c` is missing, `tree-sitter generate` is
run first.

`:KairoBuildParser` forces a rebuild. `vim.g.kairo_cc` overrides the compiler.

## What it sets up

- filetype `kairo` for `.k`, `.kairo`, `.kh`, `.kairoh`
- `queries/kairo/highlights.scm` using Neovim capture names
- `queries/kairo/injections.scm`: `inline "c++" | "c" | "asm"` bodies and
  comment tags, when those parsers are installed
- `commentstring`, `comments`, 4-space indentation

## Language server

With the Kairo toolchain on `PATH`, `kals` is started for every Kairo buffer:
diagnostics, completion, hover, go to definition, references, rename,
signature help, inlay hints, semantic highlighting. Nothing is configured.

- `:KairoFormat` formats the buffer with `kfmt` (or `vim.lsp.buf.format()`).
- `vim.g.kairo_kals = "/path/to/kals"` runs another binary.
- `vim.g.kairo_lsp = false` turns the server off.

Two highlight groups are Kairo's own, both overridable:

| Group | Default | On |
|---|---|---|
| `@lsp.mod.overloaded.kairo` | underline | a call that picks one of several overloads, or a user-defined operator |
| `@lsp.mod.dispatched.kairo` | underline, italic | a call that dispatches through `where` guards |

Projects are described by `kairo_compile.json`; see
<https://kairolang.org/docs/toolchain/kals/>.
