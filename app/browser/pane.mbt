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
  Click(PaneSide, Int32)
  DblClick(PaneSide, Int32)
  Select(PaneSide, String)
}

///|
priv struct ListingTarget {
  pane : PaneSide
  view_id : Int32
  request_id : Int32
}

///|
priv struct Pane {
  id : Int32
  path : Path
  cursor : String?
  request_id : Int32
  loading : ListingState
  refresh_pending : Bool
  entries : Array[Entry]
  visible_entries : Array[Entry]
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
fn Pane::initialize(path : Path, id~ : Int32 = 0) -> Pane {
  {
    id,
    path,
    cursor: None,
    request_id: 0,
    loading: Unloaded,
    refresh_pending: false,
    entries: [],
    visible_entries: [],
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
  }.with_filter(filter?)
  guard updated.cursor != pane.cursor else { return updated }
  guard pane.cursor_index() is Some(index) else { return updated }
  let names = Set::from_iter(
    updated.visible_entries.iter().map(entry => entry.name),
  )
  guard pane.visible_entries[index + 1:]
    .iter()
    .concat(pane.visible_entries[:index].rev_iter())
    .find_first(entry => names.contains(entry.name))
    is Some(entry) else {
    return updated
  }
  { ..updated, cursor: Some(entry.name), }
}
