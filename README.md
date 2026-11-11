# kairo-lsp

Editor support for [Kairo](https://kairolang.org). Every editor here is a thin client of the same server, `kals`, which ships with the Kairo toolchain; the server's source is in the compiler repository (`Analyzer/`).

| Directory | What it is |
|---|---|
| [`vscode/`](vscode/) | the Visual Studio Code extension |
| [`zed/`](zed/) | the Zed extension |
| [`nvim/`](nvim/) | the Neovim plugin |
| [`tree-sitter-kairo/`](tree-sitter-kairo/) | the tree-sitter grammar Zed and Neovim highlight with |

## One rule for all three

Install the Kairo toolchain so `kals`, `kfmt` and `kairo` are on `PATH`. Each client finds them there and needs no configuration; each has one setting to point at another binary.

## What you get

Diagnostics as you type with the compiler's fix-its as quick fixes, completion, semantic highlighting, hover, go to definition and type definition, references, rename, signature help, formatting with `kfmt`, outline, workspace symbols, folding and inlay hints.

Two marks are Kairo's own. A call that resolves to one of several overloads, or to a user-defined operator, carries the `overloaded` semantic-token modifier; a call that dispatches at run time through `where` guards carries `dispatched`. All three clients underline them.

## Projects

`kals` reads a project's entry points from `kairo_compile.json` in the workspace folder:

```json
{
  "version": 1,
  "entries": [
    { "entry": "src/main.k", "args": ["-I", "include/"] }
  ]
}
```

A file belongs to the entry that imports it; without the file each source file is checked on its own. Full description: <https://kairolang.org/docs/toolchain/kals/>.

## Changing the grammar or the highlighting

`tree-sitter-kairo/src/` is generated from `grammar.js` (`tree-sitter generate`) and committed, because Zed and Neovim build from the generated C. `nvim/queries/kairo/` and `zed/languages/kairo/` hold the same highlighting scheme under each editor's capture names: change both together. `vscode/public/syntaxes/` is a separate TextMate grammar.
