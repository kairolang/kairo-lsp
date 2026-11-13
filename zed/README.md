# Kairo for Zed

Language support for [Kairo](https://kairolang.org) in Zed: the `kals` language server, tree-sitter highlighting, outline, bracket matching, auto-indent and text objects.

## Install

From the extension gallery (once published): open `zed: extensions`, search for "Kairo", install.

As a dev extension:

1. Install the Kairo toolchain so `kals`, `kfmt` and `kairo` are on `PATH` (see <https://kairolang.org/docs/install/>).
2. In Zed: command palette, `zed: install dev extension`, pick this directory (`kairo-lsp/zed`). Zed compiles `src/lib.rs` to wasm, which needs a rustup-installed Rust (the `wasm32-wasip2` target is added automatically).
3. Turn semantic highlighting on for Kairo (it is off in Zed by default):

```json
"languages": { "Kairo": { "semantic_tokens": "combined" } }
```

## Requirements

`kals` on `PATH`, or its path in settings. It ships with the Kairo toolchain, beside `kairo` and `kfmt`. When it cannot be found, Zed shows an error that says so and links the install page.

## Settings

All of it is optional. In `settings.json`:

```json
{
  "languages": { "Kairo": { "semantic_tokens": "combined" } },
  "lsp": {
    "kals": {
      "binary": { "path": "/path/to/kals", "arguments": [] },
      "initialization_options": {
        "liveCheck": true,
        "debounceMs": 150,
        "syntaxDebounceMs": 100,
        "maxWorkers": 2,
        "highlightPanics": false
      }
    }
  }
}
```

`binary` runs another `kals` than the one on `PATH`. `initialization_options` goes to the server unchanged; the names and defaults are the ones in the VS Code extension (`kairo.kals.*`) and the table on the [kals page](https://kairolang.org/docs/toolchain/kals/). `highlightPanics` marks calls that can panic with the `panics` modifier; the rules file does not style it, so add a rule under `global_lsp_settings.semantic_token_rules` to see it.

## What is supported

Diagnostics as you type, quick fixes, completion, hover, go to definition and type definition, references, rename, signature help, formatting (`kfmt`), outline, workspace symbols, folding, inlay hints. From the grammar: highlighting, outline, brackets, indentation, text objects.

`languages/kairo/semantic_token_rules.json` underlines a call that resolves to one of several overloads or to a user-defined operator (`overloaded`), and a call that dispatches through `where` guards (`dispatched`, also italic), calls into C/C++ and extension calls (italic), unsafe (bold), the `&` of a call argument by the parameter it binds to (`@inout`: green; `*T`: bold in the operator colour; `unsafe *T`: purple; `*const T`: grey-blue; `unsafe *const T`: purple italic, all bold), macro invocations and definitions (`name!`, amber), deprecated uses (strikethrough) and constants (the enum-member colour). Override under `global_lsp_settings.semantic_token_rules`.

## Projects

`kals` reads the project's entry points from `kairo_compile.json` (see the [kals page](https://kairolang.org/docs/toolchain/kals/)). Without one, each file is checked on its own.

## Known limits

- Semantic highlighting is off until `semantic_tokens` is set (above); the tree-sitter colours apply meanwhile.
- `inline "asm"` bodies are not highlighted: Zed has no bundled assembly grammar to inject.
- The `mutable` modifier has no second shade in Zed.
- The dotted underline for `panics` is not drawn by Zed; use a rule of your own.
- The server options are read when it starts: restart it (`editor: restart language server`) after changing them.

## The grammar

The queries in `languages/kairo/` follow the Neovim plugin's (`../nvim/queries/kairo/`) with Zed's capture names; change both together. `extension.toml` names the grammar by git revision; if an install fails with "grammar directory ... already exists, but is not a git clone of ...", delete `grammars/kairo` here (a generated checkout) and install again.

## Publishing (maintainer)

Prerequisites Zed checks: an accepted license inside this directory (`LICENSE.txt`), a kebab-case id without "zed" or "extension" (`kairo`), a public repository, the grammar defined in `extension.toml`, the language server found rather than bundled.

1. When `tree-sitter-kairo/` changes, push the change and set `rev` under `[grammars.kairo]` in `extension.toml` to that pushed commit (full sha).
2. Check `version` in `extension.toml`, commit and push; the commit must be on a branch.
3. Fork `zed-industries/extensions`, then:

```sh
git submodule add https://github.com/kairolang/kairo-lsp.git extensions/kairo
git add extensions/kairo
```

4. Add to the top-level `extensions.toml` (`version` must equal the one in `extension.toml` at the submodule commit):

```toml
[kairo]
submodule = "extensions/kairo"
path = "zed"
version = "0.3.0"
```

5. `pnpm sort-extensions`, then open a pull request that adds only this extension.

To release an update: bump `version` here, push, then in the fork run `git submodule update --remote extensions/kairo`, set the new `version` in `extensions.toml`, and open a pull request.
