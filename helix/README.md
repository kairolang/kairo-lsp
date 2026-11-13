# Kairo for Helix

Kairo language support for Helix: the `kals` language server and syntax highlighting, text objects and indentation built on `tree-sitter-kairo`.

Requires Helix 25.01 or newer, a C compiler (Helix builds the grammar), and the Kairo toolchain (`kals`, `kfmt`) on `PATH`: <https://kairolang.org/docs/install/>.

## Install

Helix has no plugin system; a language is a config entry plus query files.

1. Add the contents of [`languages.toml`](languages.toml) to `~/.config/helix/languages.toml` (create the file if it does not exist).
2. Copy the queries into your Helix runtime:

```sh
git clone https://github.com/kairolang/kairo-lsp
mkdir -p ~/.config/helix/runtime/queries
cp -r kairo-lsp/helix/runtime/queries/kairo ~/.config/helix/runtime/queries/
```

3. Fetch and build the grammar:

```sh
hx --grammar fetch
hx --grammar build
```

4. Check it: `hx --health kairo` should find `kals` and list highlights, text objects and indents.

On Windows the config directory is `%AppData%\helix`.

## Settings

`[language-server.kals]` in `languages.toml`:

- `command` runs another `kals` than the one on `PATH`.
- `config` goes to the server as its initialization options, unchanged. The names and defaults are the ones the VS Code extension uses (`kairo.kals.*`) and the table on the [kals page](https://kairolang.org/docs/toolchain/kals/).

## What works

Diagnostics with fix-its as code actions, completion, hover, go to definition, type definition and implementation, references, rename, signature help, formatting through `kfmt` (`:format`), document and workspace symbols, and inlay hints (`lsp.display-inlay-hints = true` in `config.toml`). Text objects: `maf` / `mif` select a function (or closure), `mat` / `mit` a class, struct, interface or enum, `mia` a parameter, `mac` / `mic` a comment.

Colours come from tree-sitter. Helix does not apply the server's semantic tokens, so the marks the other clients show from them (underlined overloaded calls, the `&` of a call argument coloured by its parameter, the macro colour from the server) do not appear.

## Updating

When `tree-sitter-kairo/` changes, the `rev` in `languages.toml` moves to the new commit: copy the `[[grammar]]` entry again and the queries, then run `hx --grammar fetch` and `hx --grammar build`.
