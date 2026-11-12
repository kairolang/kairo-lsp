# Kairo for Visual Studio Code

Language support for [Kairo](https://kairolang.org), from `kals`, the Kairo language server.

## Features

- Diagnostics as you type, from the compiler itself, with its fix-its as quick fixes. Syntax errors in the file you are editing come first (a parse of that file alone), the full type check follows
- Completion: members after `.`, `->` and `::`, enum variants, names in scope
- Semantic highlighting on top of the TextMate grammar
- Go to definition, type definition and declaration; find references; rename
- Hover with signatures and `///` documentation; signature help with every overload
- Formatting with `kfmt` (format document, format on save)
- Outline, workspace symbols, folding, selection ranges, inlay hints for inferred types
- Import paths are links to the file they resolve to
- Macros: hover an invocation to see what it expands to; the quick-fix menu offers **View expanded macro** (the expansion, read-only, beside the editor) and **Expand macro here** (replaces the invocation with it)
- Progress while a workspace is first indexed

A call in Kairo can be more than it looks, and the editor shows it: a call that picks one of several **overloads**, or runs a user-defined operator, is underlined; a call that dispatches at run time through **`where`** guards is underlined and italic; a call to a method an `extend` block adds is italic.

## Getting started

1. Install the [Kairo toolchain](https://kairolang.org/install). It puts `kairo`, `kals` and `kfmt` on your `PATH`, and that is where this extension finds them.
2. Install this extension.
3. Open a `.k` file.

For a project with more than one file, run **Kairo: Create kairo_compile.json**. It names your entry point (the file you pass to `kairo`) and its flags; every other file is found through imports. Without it each file is checked on its own.

```json
{
  "version": 1,
  "entries": [
    { "entry": "src/main.k", "args": ["-I", "include/"] }
  ]
}
```

## Commands

| Command | |
|---|---|
| Kairo: Restart Language Server | restart `kals` |
| Kairo: Show Language Server Output | the server's log |
| Kairo: Create kairo_compile.json | write a starter project file |

## Settings

All optional.

| Setting | Default | |
|---|---|---|
| `kairo.kals.path` | (PATH) | run this `kals` instead |
| `kairo.kals.args` | `[]` | extra arguments for `kals` |
| `kairo.kals.debounceMs` | `150` | how long kals waits after the last keystroke before the type check |
| `kairo.kals.syntaxDebounceMs` | `100` | how long kals waits before re-parsing the edited file alone (its syntax errors, and keyword highlighting while it does not parse) |
| `kairo.kals.maxWorkers` | `2` | how many entry points kals may analyse at once |
| `kairo.kals.liveCheck` | `true` | kals keeps one compiler process per entry and re-checks an edit in place; off: a new process re-checks the project on every edit |
| `kairo.completion.triggerOnDelete` | `true` | show completions again after a deletion that leaves the cursor in or right after a name |
| `kairo.trace.server` | `off` | log LSP messages to the Kairo output channel |

To change how overloaded and `where`-dispatched calls are drawn:

```json
"editor.semanticTokenColorCustomizations": {
  "rules": {
    "*.overloaded:kairo": { "underline": false, "bold": true },
    "*.dispatched:kairo": { "underline": true }
  }
}
```

## Building from source

```sh
cd vscode
npm install
npm run build
npx vsce package
```

Install the `.vsix` from Extensions, "...", "Install from VSIX".
