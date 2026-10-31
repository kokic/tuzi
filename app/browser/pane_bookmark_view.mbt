///|
fn pane_bookmark_menu_view(
  id : String,
  current : Path,
  bookmarks : Array[Path],
  idx : PaneSide,
  emit : Emit[Msg],
) -> Val[Html] {
  pane_path_menu_view(
    id,
    current,
    bookmarks.map(path => path.to_string()),
    idx,
    emit,
    label="Bookmarks",
    empty_label="No bookmarks yet",
  )
}
