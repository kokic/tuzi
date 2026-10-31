///|
fn Pane::cursor_index(pane : Pane) -> Int32? {
  pane.visible_entries.search_by(entry => Some(entry.name) == pane.cursor)
}

///|
fn Pane::cursor_entry(pane : Pane) -> Entry? {
  guard pane.cursor is Some(name) else { return None }
  pane.entries.iter().find_first(entry => entry.name == name)
}

///|
fn Pane::selected_items(pane : Pane) -> Array[Entry] {
  guard !pane.selected.is_empty() else {
    return pane.cursor_entry().map_or([], entry => [entry])
  }
  pane.entries.filter(entry => pane.selected.contains(entry.name))
}

///|
fn Pane::move_cursor(pane : Pane, delta : Int32) -> Pane {
  let entries = pane.visible_entries
  guard !entries.is_empty() else { return { ..pane, cursor: None, } }
  let index = (pane.cursor_index().unwrap_or(0) + delta).clamp(
    min=0,
    max=entries.length() - 1,
  )
  { ..pane, cursor: Some(entries[index].name), }
}

///|
fn Pane::toggle_cursor_selection(pane : Pane) -> Pane {
  guard pane.cursor_index() is Some(index) else { return pane }
  let entry = pane.visible_entries[index]
  let next = pane.visible_entries.get(index + 1).unwrap_or(entry)
  { ..pane.toggle_entry_selection(entry.name), cursor: Some(next.name), }
}

///|
fn Pane::toggle_entry_selection(pane : Pane, name : String) -> Pane {
  let selected = pane.selected.copy()
  if !selected.remove_and_check(name) {
    selected.add(name)
  }
  { ..pane, selected, }
}
