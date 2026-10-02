///|
priv enum PaneMsg {
  ListLoaded(
    Array[ListingTarget],
    Path,
    Bool,
    Result[Array[Entry], RequestFailure]
  )
  ReloadPane(PaneSide)
  GotoPath(PaneSide, Path)
  Click(PaneSide, Int)
  DblClick(PaneSide, Int)
  Select(PaneSide, String)
}

///|
priv struct ListingTarget {
  pane : PaneSide
  view_id : Int
  request_id : Int
}

///|
priv struct Pane {
  id : Int
  path : Path
  cursor : String?
  request_id : Int
  loading : ListingState
  // Coalesce invalidations during a request into one subsequent reload.
  refresh_pending : Bool
  // Stored in display order; readers must not mutate this array.
  entries : Array[Entry]
  // Copy before mutation: retained models share selection membership.
  selected : Set[String]
} derive(Eq)

///|
priv enum ListingState {
  Unloaded
  Loading
  Ready
  LoadFailed(String)
} derive(Eq)

///|
/// A projection for one render or cursor operation, never stored in Model.
priv struct PaneViewData {
  entries : Array[Entry]
  cursor_index : Int?
}

///|
fn Pane::view_data(pane : Pane, filter? : String) -> PaneViewData {
  let entries = pane.visible_entries(filter?)
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
fn Pane::cursor_index(pane : Pane, filter? : String) -> Int {
  pane.view_data(filter?).cursor_index.unwrap_or(0)
}

///|
fn Pane::cursor_entry(pane : Pane, filter? : String) -> Entry? {
  guard pane.cursor is Some(name) &&
    filter.map_or(true, query => name.contains(query)) else {
    return None
  }
  pane.entries.iter().find_first(entry => entry.name == name)
}

///|
fn Pane::with_filter(pane : Pane, filter? : String) -> Pane {
  let entries = pane.visible_entries(filter?)
  let cursor = if entries.any(entry => Some(entry.name) == pane.cursor) {
    pane.cursor
  } else {
    entries.get(0).map(entry => entry.name)
  }
  { ..pane, cursor, }
}

///|
/// Entries to operate on: the current selection, or the cursor entry when
/// nothing is selected.
fn Pane::selected_items(pane : Pane, filter? : String) -> Array[Entry] {
  guard !pane.selected.is_empty() else {
    return pane.cursor_entry(filter?).map_or([], entry => [entry])
  }
  pane.entries.filter(entry => {
    pane.selected.contains(entry.name) &&
    filter.map_or(true, query => entry.name.contains(query))
  })
}

///|
fn Pane::selected_entry(pane : Pane, filter? : String) -> Entry? {
  let items = pane.selected_items(filter?)
  guard items.length() == 1 else { return None }
  items.get(0)
}

///|
/// Entries are sorted when stored. With no filter, reuse them without allocation.
fn Pane::visible_entries(pane : Pane, filter? : String) -> Array[Entry] {
  guard filter is Some(query) else { return pane.entries }
  pane.entries.filter(entry => entry.name.contains(query))
}

///|
fn Pane::move_cursor(pane : Pane, filter? : String, delta : Int) -> Pane {
  let data = pane.view_data(filter?)
  let entries = data.entries
  guard !entries.is_empty() else { return { ..pane, cursor: None, } }
  let index = (data.cursor_index.unwrap_or(0) + delta).clamp(
    min=0,
    max=entries.length() - 1,
  )
  { ..pane, cursor: Some(entries[index].name), }
}

///|
fn Pane::toggle_cursor_selection(pane : Pane, filter? : String) -> Pane {
  let data = pane.view_data(filter?)
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

///|
fn Pane::initialize(path : Path, id? : Int = 0) -> Pane {
  {
    id,
    path,
    cursor: None,
    request_id: 0,
    loading: Unloaded,
    refresh_pending: false,
    entries: [],
    selected: Set([]),
  }
}

///|
fn Pane::begin_loading(pane : Pane) -> Pane {
  {
    ..pane,
    request_id: pane.request_id + 1,
    loading: Loading,
    refresh_pending: false,
  }
}

///|
/// Replace listing data without mutating arrays held by the previous model.
fn Pane::with_entries(
  pane : Pane,
  entries : Array[Entry],
  sort : SortMode,
  filter? : String,
) -> Pane {
  let entries = entries.copy()
  entries.sort_by((left, right) => sort.compare_entries(left, right))
  let updated = {
    ..pane,
    entries,
    selected: if pane.selected.is_empty() {
      pane.selected
    } else {
      Set::from_iter(
        entries
        .iter()
        .filter(entry => pane.selected.contains(entry.name))
        .map(entry => entry.name),
      )
    },
  }
  let data = updated.view_data(filter?)
  guard data.cursor_index is None else { return updated }
  let previous = pane.view_data(filter?)
  guard previous.cursor_index is Some(index) else {
    return updated.with_filter(filter?)
  }
  // Keep the cursor near the removed entry in the previous visible order.
  let names = Set::from_iter(data.entries.iter().map(entry => entry.name))
  guard previous.entries[index + 1:]
    .iter()
    .concat(previous.entries[:index].rev_iter())
    .find_first(entry => names.contains(entry.name))
    is Some(entry) else {
    return updated.with_filter(filter?)
  }
  { ..updated, cursor: Some(entry.name), }
}
