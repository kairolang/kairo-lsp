# Kairo for Zed

Language support for [Kairo](https://kairolang.org) in Zed: the `kals` language server, tree-sitter highlighting, outline, bracket matching, auto-indent, text objects, and C / C++ / asm highlighting inside `inline "c++" { ... }` bodies.

## Install

1. Install the Kairo toolchain so `kals`, `kfmt` and `kairo` are on `PATH`.
2. In Zed: command palette, `zed: install dev extension`, pick this directory (`kairo-lsp/zed`). Zed compiles `src/lib.rs` to wasm, which needs a rustup-installed Rust.
3. Turn semantic highlighting on for Kairo (it is off in Zed by default):

```json
"languages": { "Kairo": { "semantic_tokens": "combined" } }
```

Nothing else is configured. To run a `kals` that is not on `PATH`:

```json
"lsp": { "kals": { "binary": { "path": "/path/to/kals" } } }
```

## What the server adds

Diagnostics as you type, quick fixes, completion, hover, go to definition and type definition, references, rename, signature help, formatting (`kfmt`), outline, workspace symbols, folding, inlay hints.

`languages/kairo/semantic_token_rules.json` underlines a call that resolves to one of several overloads or to a user-defined operator (`overloaded`), and a call that dispatches through `where` guards (`dispatched`, also italic). Override under `global_lsp_settings.semantic_token_rules`.

## Projects

`kals` reads the project's entry points from `kairo_compile.json` (see the [kals page](https://kairolang.org/docs/toolchain/kals/)). Without one, each file is checked on its own.

## The grammar

`extension.toml` names the grammar by git revision; see the comment there. The queries in `languages/kairo/` follow the Neovim plugin's (`../nvim/queries/kairo/`) with Zed's capture names; change both together.

If an install fails with "grammar directory ... already exists, but is not a git clone of ...", delete `grammars/kairo` here (a generated checkout) and install again.
