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

See Help in the app for the complete operating guide.

## Build & Run

```sh
warren build --bundle --browser-entry app/browser --server-entry app/tuzi
./dist/tuzi.exe [path]
./dist/tuzi.exe --help
```

Development:

```sh
warren dev --server-target native --browser-entry app/browser --server-entry app/tuzi
```
