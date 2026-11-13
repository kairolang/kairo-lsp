// --- The Kairo Project -------------- zed/src/lib.rs
//
//   Starts kals, the Kairo language server, for Zed.
//
//   The grammar, queries and language config need no code; a language server
//   does, because Zed asks the extension what to run. The answer is the
//   `kals` on the worktree's PATH (it ships beside `kairo` and `kfmt`), or
//   the path the user set under `lsp.kals.binary.path`. Settings under
//   `lsp.kals.initialization_options` are passed to the server unchanged.
//
//   SPDX-License-Identifier: Apache-2.0 WITH AdditionRef-Kairo-Runtime-exception
//   Copyright (c) 2026 Dhruvan Kartik

use zed_extension_api::{self as zed, settings::LspSettings, LanguageServerId, Result};

struct KairoExtension;

impl zed::Extension for KairoExtension {
    fn new() -> Self {
        KairoExtension
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        // A path from settings wins: a contributor points this at
        // build/<triple>/debug/bin/kals without touching PATH.
        let binary = LspSettings::for_worktree(language_server_id.as_ref(), worktree)
            .ok()
            .and_then(|s| s.binary);
        let args = binary
            .as_ref()
            .and_then(|b| b.arguments.clone())
            .unwrap_or_default();

        let command = match binary.and_then(|b| b.path) {
            Some(path) => path,
            None => worktree.which("kals").ok_or_else(|| {
                "kals was not found on PATH. Install the Kairo toolchain \
                 (https://kairolang.org/docs/install/), or set \
                 lsp.kals.binary.path in settings. Server settings: \
                 https://kairolang.org/docs/toolchain/kals/"
                    .to_string()
            })?,
        };

        Ok(zed::Command {
            command,
            args,
            env: worktree.shell_env(),
        })
    }

    fn language_server_initialization_options(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<zed::serde_json::Value>> {
        Ok(LspSettings::for_worktree(language_server_id.as_ref(), worktree)
            .ok()
            .and_then(|s| s.initialization_options))
    }
}

zed::register_extension!(KairoExtension);
