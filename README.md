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

## Usage

- Double-click a folder or file to open it. Right-click or press `a` on the current item for actions such as copy, move, rename, delete, and ZIP compression.
- Use the two panes to work across folders: `c` copies selected items to the other pane, and `m` moves them.
- Use `Tab` to switch panes, `↑` / `↓` to move through items, and `Space` to select multiple items. `Enter` opens an item; `Esc` goes up a folder.
- Press `f` to filter files by name.
- Press `s` or click a pane's sort button to change its sort order independently.
- Press `?` to see all keyboard shortcuts.

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
