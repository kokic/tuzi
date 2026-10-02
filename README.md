# Tuzi

## Features

- Dual-pane file browser with a web UI.
- Never generates or packages junk files like `.DS_Store` and `__MACOSX/`, even on macOS.

## Acknowledgements

The following projects have had a profound and lasting influence on Tuzi's design and aesthetics.

- Thanks to MT Manager and its developer, Bin.
- Thanks to ZArchiver and its development team, [ZDevs](https://www.zdevs.ru).
- Thanks to [Yazi](https://yazi-rs.github.io) and its developer, 三咲雅.
- Thanks to [fd](https://github.com/sharkdp/fd) and its developer, David Peter.

I would also like to thank the Web UI framework [Rabbita](https://moonbit-community.github.io/rabbita) and its creator, [Yorkin](https://github.com/Yoorkin).

## Build & Run

```sh
warren build --bundle --browser-entry app/browser --server-entry app/tuzi
./dist/tuzi.exe [path]    # opens the browser at the configured port
```

Pass `path` to open it in both panes. Without it, restore the last locations or
use the current working directory. Locations are saved per browser origin,
regardless of the startup directory.

The bundle embeds the frontend and `public/` resources in `dist/tuzi.exe`, which
can run from any directory. Keep `app/tuzi/warren_assets.mbt` in version control;
Warren supplies its contents when bundling. For separate frontend files, replace
`--bundle` with `--server-target native` and keep the `dist/` files together.

Choose a theme with `--theme dark` or `--theme light`.
Run `./dist/tuzi.exe --help` to see the default theme.

Use `--port` / `-p` to select a port (default: 4000). During `warren dev`,
Warren's `WARREN_PORT` setting selects the port.

Dev with live reload (builds browser + server, opens preview):

```sh
warren dev --server-target native --browser-entry app/browser --server-entry app/tuzi
```

## Usage

Each pane's bar shows the total number of items and the number of selected items.

- `Tab`/`←`/`→` switch the active pane
- `↑↓` move, `Enter` enter a directory or open the file under the cursor, `Esc` up, `Space` multi-select
- Double-click also enters a directory or opens a file. Markdown (`.md` / `.markdown`, case-insensitive) opens in a dialog with Preview / Code icon tabs for rendered content and original text. Other known formats use the browser's native viewer in a new tab. Unknown formats up to and including 1 MiB (1,048,576 bytes) open as plain text; larger files show an unsupported-format toast without opening a tab or downloading. HTML and SVG documents are sandboxed with scripts disabled.
- `o` or **Open with…** chooses how to open the file or folder under the cursor. Source/text files such as `.c` and `.md` can open in VSCode; folders can open in Tuzi, the system file manager (Explorer on Windows), or VSCode. External applications run on the computer hosting Tuzi and must be installed there.
- `c`/`m` copy/move to the other pane (drag & drop works too)
- `d` delete, `r` rename, `n` new dir, `s` sort, `y` copy path, `f` filter
- `i` shows information for the file or folder under the cursor: name, full path, type, file size in bytes, and modification time in UTC (including seconds). Folder sizes are neither calculated nor shown. `Esc`/Close/`×`/click outside closes the dialog.
  Unavailable metadata is shown as unknown; a failed modification-time lookup does not discard an available file size.
- `z` compress the selected items (or the item under the cursor) into a ZIP archive in the same directory. The dialog lets you set the archive name and compression level (0–9, default 6). Level 0 disables Deflate compression; higher levels favor smaller files over speed. Known compressed file types are stored without recompression at every level.
- `?` opens the keymap help dialog (`Esc`/`×`/click outside closes it)

File operations are logged to the server's stdout.

## Openers

Configure opening methods in `app/tuzi/open_config.mbt`, like the code-defined
icon registry. `configured_openers` defines each opener once with its label and
built-in action or external program. External arguments are an array of
`Literal("...")` and `Target` values, passed directly to the program without
a shell. The platform is available when choosing programs and arguments.

`app/tuzi/platform.mbt` detects the platform once at startup and selects system
opening commands for URLs and directories. Explicit applications such as VSCode
keep their own program and arguments in the opener configuration. Both use
`OpenCommand::launch` to start the process; URL targets stay URLs and filesystem
targets use resolved native paths.

`configured_open_registry` associates opener IDs with folders, lowercase complete
filenames, extensions without a leading dot, and other files. Complete filenames
take precedence over extensions. Each association supplies its entire ordered
`openers` list and a separate `default_opener` from that list. Multiple extensions
can share an association, and an opener such as `vscode` can be reused for both
files and folders. Enter and double-click use the configured default; changing
menu order does not change that default. The initial defaults are directory
navigation, ZIP extraction, and browser preview.

Windows VSCode discovery checks PATH and standard user/system installation
locations for `Code.exe`; custom installations can set the program explicitly in
the opener configuration. Rebuild Tuzi after changing this code configuration.
