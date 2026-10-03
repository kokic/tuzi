///|
/// Keep the directory marker visible when the filename is truncated.
fn entry_name_view(entry : Entry, color : String) -> Html {
  span(
    style=entry_title_style(entry, color),
    title=if entry.is_dir { entry.name + "/" } else { entry.name },
    [
      span(
        style=["min-width: 0", "overflow: hidden", "text-overflow: ellipsis"],
        entry.name,
      ),
      ..if entry.is_dir {
        [span(style=["flex: none"], "/")]
      } else {
        []
      },
      ..if entry.is_symlink {
        [
          span(
            style=["flex: none", "margin-left: 4px"],
            title="Symbolic link",
            "↗",
          ),
        ]
      },
    ],
  )
}
