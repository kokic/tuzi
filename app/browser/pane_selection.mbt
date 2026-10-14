///|
/// A projection for one render or cursor operation, never stored in Model.
priv struct PaneViewData {
  entries : Array[Entry]
  cursor_index : Int32?
}

///|
fn Pane::view_data(pane : Pane) -> PaneViewData {
  let entries = pane.visible_entries
  {
    entries,
    cursor_index: entries.search_by(entry => Some(entry.name) == pane.cursor),
  }
}

///|
fn PaneViewData::cursor_entry(self : PaneViewData) -> Entry? {
  self.cursor_index.map(index => self.entries[index])
}

///|
fn Pane::cursor_index(pane : Pane) -> Int32 {
  pane.view_data().cursor_index.unwrap_or(0)
}

///|
fn Pane::cursor_entry(pane : Pane) -> Entry? {
  guard pane.cursor is Some(name) else { return None }
  pane.entries.iter().find_first(entry => entry.name == name)
}

///|
/// Entries to operate on: the current selection, or the cursor entry when
/// nothing is selected.
fn Pane::selected_items(pane : Pane) -> Array[Entry] {
  guard !pane.selected.is_empty() else {
    return pane.cursor_entry().map_or([], entry => [entry])
  }
  pane.entries.filter(entry => pane.selected.contains(entry.name))
}

///|
fn Pane::move_cursor(pane : Pane, delta : Int32) -> Pane {
  let data = pane.view_data()
  let entries = data.entries
  guard !entries.is_empty() else { return { ..pane, cursor: None, } }
  let index = (data.cursor_index.unwrap_or(0) + delta).clamp(
    min=0,
    max=entries.length() - 1,
  )
  { ..pane, cursor: Some(entries[index].name), }
}

///|
fn Pane::toggle_cursor_selection(pane : Pane) -> Pane {
  let data = pane.view_data()
  guard data.cursor_index is Some(index) else { return pane }
  let entry = data.entries[index]
  let next = data.entries.get(index + 1).unwrap_or(entry)
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
