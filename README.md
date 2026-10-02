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
- Right-click a file or folder for opening methods, copy/move to the other pane, rename, copy path, ZIP compression, information, new file or folder, and delete. Actions use the clicked item, or the current selection when the clicked item is selected; rename requires a single item and information shows the clicked item. Delete opens the existing confirmation dialog. Source/text files such as `.c` and `.md` can open in VSCode; folders can open in Tuzi, the system file manager (Explorer on Windows), or VSCode. External applications run on the computer hosting Tuzi and must be installed there.
- `c`/`m` copy/move to the other pane (drag & drop works too)
- `d` delete, `r` rename, `n` new file or folder, `s` sort, `y` copy path
- In the `n` dialog, enter a name and choose `File` to create an empty file or `Folder` to create a directory. `Enter` creates a folder. Existing entries are not overwritten.
- `f` focuses the active pane's filter at the right of its bottom status bar. Each pane keeps its own filter when switching panes; `Esc` leaves the filter input and `×` clears that pane's filter.
- `i` shows information for the file or folder under the cursor: name, full path, type, file size in bytes, and modification time in UTC (including seconds). Folder sizes are neither calculated nor shown. `Esc`/Close/`×`/click outside closes the dialog.
  Unavailable metadata is shown as unknown; a failed modification-time lookup does not discard an available file size.
- `z` compress the selected items (or the item under the cursor) into a ZIP archive in the same directory. The dialog lets you set the archive name and compression level (0–9, default 6). Level 0 disables Deflate compression; higher levels favor smaller files over speed. Known compressed file types are stored without recompression at every level.
- `?` opens the keymap help dialog (`Esc`/`×`/click outside closes it)

File operations are logged to the server's stdout.

## Openers

Configure opening methods in `app/tuzi/open_config.mbt`, like the code-defined
file color registry. `configured_openers` defines each opener once with its label and
built-in action or external program. External arguments are an array of
`Literal("...")` and `Target` values, passed to the configured program.

`app/tuzi/platform.mbt` uses `#cfg(platform=...)` for Windows, macOS, and Linux
to select system opening commands for URLs and directories at compile time.
Explicit applications such as VSCode keep their own program and arguments in
the opener configuration, with the same conditional compilation. Both use
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

VSCode uses `code` on PATH on Windows and Linux, with Windows invoking it through
`cmd /d /c`. macOS uses `open -a "Visual Studio Code"`. No installation-directory
discovery is performed. Rebuild Tuzi after changing this code configuration.
