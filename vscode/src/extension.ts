// Kairo for Visual Studio Code.
//
// The extension is a thin client: it starts `kals`, the Kairo language
// server, and everything the editor shows (diagnostics, completion, semantic
// highlighting, formatting, navigation) comes from it over LSP. The tools are
// found on PATH, which is where the Kairo toolchain installs them; a setting
// overrides each for a contributor running a build tree.

import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import * as vscode from "vscode";
import {
    CloseAction,
    ErrorAction,
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    State,
} from "vscode-languageclient/node";

let client: LanguageClient | undefined;
let output: vscode.OutputChannel;
let status: vscode.StatusBarItem;

// --- finding the tools -------------------------------------------------------

/** `name` on PATH, with the platform's executable extensions; undefined if absent. */
function onPath(name: string): string | undefined {
    const exts = process.platform === "win32" ? (process.env.PATHEXT ?? ".EXE;.CMD;.BAT").split(";") : [""];
    for (const dir of (process.env.PATH ?? "").split(path.delimiter)) {
        if (!dir) {
            continue;
        }
        for (const ext of exts) {
            const candidate = path.join(dir, name + ext);
            try {
                fs.accessSync(candidate, fs.constants.X_OK);
                if (fs.statSync(candidate).isFile()) {
                    return candidate;
                }
            } catch {
                // not here
            }
        }
    }
    // A GUI-launched editor may not have the login shell's PATH. These are
    // where the installer puts the toolchain.
    for (const dir of [path.join(os.homedir(), ".local", "bin"), path.join(os.homedir(), ".kairo", "bin"), "/usr/local/bin"]) {
        const candidate = path.join(dir, name + (process.platform === "win32" ? ".exe" : ""));
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    return undefined;
}

/** The configured path for a tool, or the one on PATH. */
function tool(setting: string, name: string): string | undefined {
    const configured = vscode.workspace.getConfiguration("kairo").get<string>(setting, "").trim();
    if (configured) {
        return configured.replace(/^~(?=$|\/|\\)/, os.homedir());
    }
    return onPath(name);
}

// --- the server ---------------------------------------------------------------

async function start(context: vscode.ExtensionContext): Promise<void> {
    await stop();

    const kals = tool("kals.path", "kals");
    if (!kals) {
        status.text = "$(warning) kals";
        status.tooltip = "kals (the Kairo language server) was not found on PATH";
        status.show();
        const pick = await vscode.window.showWarningMessage(
            "kals, the Kairo language server, was not found on PATH. Install the Kairo toolchain, or set kairo.kals.path.",
            "Install Kairo",
            "Open Settings"
        );
        if (pick === "Install Kairo") {
            vscode.env.openExternal(vscode.Uri.parse("https://kairolang.org/install"));
        } else if (pick === "Open Settings") {
            vscode.commands.executeCommand("workbench.action.openSettings", "kairo.kals.path");
        }
        return;
    }

    const args = vscode.workspace.getConfiguration("kairo").get<string[]>("kals.args", []);
    output.appendLine(`starting ${kals} ${args.join(" ")}`);

    const serverOptions: ServerOptions = { command: kals, args, options: { env: process.env } };
    const clientOptions: LanguageClientOptions = {
        documentSelector: [
            { scheme: "file", language: "kairo" },
            { scheme: "untitled", language: "kairo" },
        ],
        outputChannel: output,
        initializationOptions: {
            debounceMs: vscode.workspace.getConfiguration("kairo").get<number>("kals.debounceMs", 150),
            syntaxDebounceMs: vscode.workspace.getConfiguration("kairo").get<number>("kals.syntaxDebounceMs", 100),
            maxWorkers: vscode.workspace.getConfiguration("kairo").get<number>("kals.maxWorkers", 2),
            highlightPanics: vscode.workspace.getConfiguration("kairo").get<boolean>("highlight.panics", false),
            liveCheck: vscode.workspace.getConfiguration("kairo").get<boolean>("kals.liveCheck", false),
        },
        synchronize: {
            // A project file or a source file changed on disk (a checkout, a
            // generator): the server re-analyses what read it.
            fileEvents: [
                vscode.workspace.createFileSystemWatcher("**/kairo_compile.json"),
                vscode.workspace.createFileSystemWatcher("**/*.{k,kairo,kh,kairoh}"),
            ],
        },
        errorHandler: {
            error: () => ({ action: ErrorAction.Continue }),
            // The server is restarted a few times and then left down, so a
            // server that dies at startup does not loop forever.
            closed: (() => {
                let restarts = 0;
                let windowStart = Date.now();
                return () => {
                    if (Date.now() - windowStart > 3 * 60 * 1000) {
                        restarts = 0;
                        windowStart = Date.now();
                    }
                    restarts += 1;
                    if (restarts > 4) {
                        return {
                            action: CloseAction.DoNotRestart,
                            message: "kals stopped 5 times in 3 minutes and was not restarted. See the Kairo output; run 'Kairo: Restart Language Server' to try again.",
                        };
                    }
                    return { action: CloseAction.Restart };
                };
            })(),
        },
    };

    client = new LanguageClient("kairo", "Kairo", serverOptions, clientOptions);
    client.onDidChangeState((e) => {
        if (e.newState === State.Running) {
            status.text = "$(check) kals";
            status.tooltip = `Kairo language server: running\n${kals}`;
        } else if (e.newState === State.Starting) {
            status.text = "$(sync~spin) kals";
            status.tooltip = "Kairo language server: starting";
        } else {
            status.text = "$(circle-slash) kals";
            status.tooltip = "Kairo language server: stopped";
        }
        status.show();
    });

    try {
        await client.start();
    } catch (err) {
        output.appendLine(`kals failed to start: ${err}`);
        vscode.window.showErrorMessage(`kals failed to start: ${err}`);
    }
}

async function stop(): Promise<void> {
    const old = client;
    client = undefined;
    if (old) {
        try {
            await old.stop();
        } catch {
            // already gone
        }
    }
}

// --- commands -----------------------------------------------------------------

/** Writes a starter kairo_compile.json for the workspace and opens it. */
async function createProjectFile(): Promise<void> {
    const folder = vscode.workspace.workspaceFolders?.[0];
    if (!folder) {
        vscode.window.showInformationMessage("Open a folder first: kairo_compile.json lives at its root.");
        return;
    }
    const target = vscode.Uri.joinPath(folder.uri, "kairo_compile.json");
    if (fs.existsSync(target.fsPath)) {
        await vscode.window.showTextDocument(target);
        return;
    }

    // The entry is the file kairo is given. Offer the open file, then the
    // usual names.
    const active = vscode.window.activeTextEditor?.document;
    const candidates: string[] = [];
    if (active && active.languageId === "kairo" && active.uri.scheme === "file") {
        candidates.push(path.relative(folder.uri.fsPath, active.uri.fsPath).split(path.sep).join("/"));
    }
    for (const guess of ["src/main.k", "main.k"]) {
        if (fs.existsSync(path.join(folder.uri.fsPath, guess)) && !candidates.includes(guess)) {
            candidates.push(guess);
        }
    }
    const entry = await vscode.window.showInputBox({
        title: "Entry point",
        prompt: "The file you pass to `kairo` (other files are found through imports)",
        value: candidates[0] ?? "src/main.k",
    });
    if (!entry) {
        return;
    }
    // `-I include/` when the project has one: the usual home of C and C++
    // headers a Kairo file imports through ffi.
    const args: string[] = [];
    if (fs.existsSync(path.join(folder.uri.fsPath, "include"))) {
        args.push("-I", "include/");
    }
    const doc = { version: 1, entries: [{ entry, args }] };
    fs.writeFileSync(target.fsPath, JSON.stringify(doc, null, 2) + "\n");
    await vscode.window.showTextDocument(target);
}

// --- macro expansion ----------------------------------------------------------

// "View expanded macro" (a kals code action) runs kairo.showMacroExpansion
// with [uri, range, text]: the invocation and what the preprocessor turns it
// into. The text is shown in a read-only virtual document beside the editor,
// one per invocation, so asking again for the same one reuses its tab.
const EXPANSION_SCHEME = "kairo-expansion";
const expansions = new Map<string, string>();
const expansionChanged = new vscode.EventEmitter<vscode.Uri>();

const expansionProvider: vscode.TextDocumentContentProvider = {
    onDidChange: expansionChanged.event,
    provideTextDocumentContent(uri: vscode.Uri): string {
        return expansions.get(uri.toString()) ?? "";
    },
};

interface LspRange {
    start: { line: number; character: number };
    end: { line: number; character: number };
}

async function showMacroExpansion(source: string, range: LspRange, text: string): Promise<void> {
    if (typeof source !== "string" || typeof text !== "string" || !range?.start) {
        return;
    }
    const file = vscode.Uri.parse(source);
    const name = path.posix.basename(file.path);
    // The path names the invocation; the query keeps two files of one name apart.
    const uri = vscode.Uri.from({
        scheme: EXPANSION_SCHEME,
        path: `/${name}:${range.start.line + 1}:${range.start.character + 1} (expanded).k`,
        query: file.toString(),
    });
    expansions.set(uri.toString(), text + "\n");
    expansionChanged.fire(uri);
    let doc = await vscode.workspace.openTextDocument(uri);
    if (doc.languageId !== "kairo") {
        doc = await vscode.languages.setTextDocumentLanguage(doc, "kairo");
    }
    await vscode.window.showTextDocument(doc, { viewColumn: vscode.ViewColumn.Beside, preview: true, preserveFocus: true });
}

// --- activation ---------------------------------------------------------------

export async function activate(context: vscode.ExtensionContext): Promise<void> {
    output = vscode.window.createOutputChannel("Kairo");
    status = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 0);
    status.command = "kairo.showOutput";
    context.subscriptions.push(output, status);

    context.subscriptions.push(
        vscode.commands.registerCommand("kairo.restartServer", () => start(context)),
        // The name older versions of this extension registered.
        vscode.commands.registerCommand("kairo.restartLSP", () => start(context)),
        vscode.commands.registerCommand("kairo.showOutput", () => output.show()),
        vscode.commands.registerCommand("kairo.createProjectFile", createProjectFile),
        vscode.commands.registerCommand("kairo.showMacroExpansion", showMacroExpansion),
        vscode.workspace.registerTextDocumentContentProvider(EXPANSION_SCHEME, expansionProvider),
        expansionChanged,
        vscode.workspace.onDidChangeConfiguration((e) => {
            if (e.affectsConfiguration("kairo.kals")) {
                start(context);
            }
        })
    );

    await start(context);
}

export function deactivate(): Thenable<void> | undefined {
    return stop();
}
