///|
/// Keep the item's path with the action, independent of the current cursor.
priv struct OpenTarget {
  pane : PaneSide
  path : Path
  entry : Entry
}

///|
fn Model::cursor_open_target(model : Model) -> OpenTarget? {
  let pane = model.pane_at(model.active)
  let data = pane.view_data(filter?=model.entry_filter(model.active))
  data.entries
  .get(data.cursor_index.unwrap_or(0))
  .map(entry => {
    pane: model.active,
    path: pane.path.join(Path("./\{entry.name}")),
    entry,
  })
}

///|
fn OpenTarget::unavailable_reason(
  self : OpenTarget,
  action : @tuzi.OpenAction,
) -> String? {
  guard self.entry.kind is Ok(kind) else {
    return Some(self.entry.kind.unwrap_err().message)
  }
  guard !(kind is UnresolvedLink(_)) else {
    return Some("The link target is unavailable.")
  }
  match action {
    Browse =>
      if kind.is_dir() {
        None
      } else {
        Some("Select a directory to enter.")
      }
    Preview => {
      guard !kind.is_dir() else {
        return Some("Directories cannot be previewed as files.")
      }
      // Missing listing metadata is checked by the existing file endpoint.
      guard self.entry.size
        .unwrap_or(None)
        .map_or(true, size => preview_content_type(self.path, size) is Some(_)) else {
        return Some(
          "Unknown formats can only be opened as text when at most 1 MiB.",
        )
      }
      None
    }
    ExtractZip => {
      guard !kind.is_dir() && self.entry.name.to_lower().has_suffix(".zip") else {
        return Some("Select a ZIP file to extract.")
      }
      None
    }
    External => None
  }
}
