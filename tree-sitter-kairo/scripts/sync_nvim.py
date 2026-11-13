#!/usr/bin/env python3
"""Copy the generated parser into nvim/tree-sitter-kairo, the copy the Neovim
plugin builds from when it is installed without its sibling directory.
Run after `tree-sitter generate`; `--check` exits 1 when the copy is stale."""
import filecmp, shutil, sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "src"
DST = SRC.parent.parent / "nvim" / "tree-sitter-kairo" / "src"
FILES = ["parser.c", "scanner.c", "tree_sitter/alloc.h", "tree_sitter/array.h", "tree_sitter/parser.h"]

stale = [f for f in FILES if not (DST / f).is_file() or not filecmp.cmp(SRC / f, DST / f, shallow=False)]
if "--check" in sys.argv:
    print("stale: " + ", ".join(stale) if stale else "nvim grammar copy is current")
    sys.exit(1 if stale else 0)
for f in stale:
    (DST / f).parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SRC / f, DST / f)
print("copied %d file(s)" % len(stale))
