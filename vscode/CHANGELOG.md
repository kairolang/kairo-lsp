# Changelog

## 0.6.0

- The extension now runs `kals`, the Kairo language server built from the compiler. The Python server and its virtual environment are gone, and so is the Python requirement.
- `kals`, `kfmt` and `kairo` are found on `PATH`; `kairo.kals.path` overrides the server. `kairo.path`, `kairo.pythonPath` and `kairo.serverPath` are removed.
- New: completion, semantic highlighting, quick fixes from compiler fix-its, formatting with `kfmt`, rename, references, signature help, type definition, workspace symbols, folding, inlay hints, document links.
- New: calls that resolve to an overload or a user-defined operator are underlined; calls that dispatch through `where` guards are underlined and italic.
- New: `kairo_compile.json` (project entry points) with a JSON schema, and **Kairo: Create kairo_compile.json**.
- **Kairo: Show IR** is removed.


All notable changes to the "Kairo" extension will be documented in this file.

Check [Keep a Changelog](http://keepachangelog.com/) for recommendations on how to structure this file.

## [Unreleased]

- Initial release