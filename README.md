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
- `↑↓` move, `Enter` enter a directory or open the file under the cursor in a new browser tab, `Esc` up, `Space` multi-select
- Double-click also enters a directory or opens a file. Known formats use the browser's native viewer. Unknown formats up to and including 1 MiB (1,048,576 bytes) open as plain text; larger files show an unsupported-format toast without opening a tab or downloading. HTML and SVG documents are sandboxed with scripts disabled.
- `c`/`m` copy/move to the other pane (drag & drop works too)
- `d` delete, `r` rename, `n` new dir, `s` sort, `y` copy path, `f` filter
- `i` shows information for the file or folder under the cursor: name, full path, type, file size in bytes, and modification time in UTC (including seconds). Folder sizes are neither calculated nor shown. `Esc`/Close/`×`/click outside closes the dialog.
  Unavailable metadata is shown as unknown; a failed modification-time lookup does not discard an available file size.
- `z` compress the selected items (or the item under the cursor) into a ZIP archive in the same directory
- `?` opens the keymap help dialog (`Esc`/`×`/click outside closes it)

File operations are logged to the server's stdout.
