///|
priv struct PaneStack {
  sort : SortMode
  current : Pane
  parents : Array[Pane]
  history : Set[String]
  next_id : Int32
} derive(Eq)

///|
fn PaneStack::initialize(path : Path) -> PaneStack {
  {
    sort: Name,
    current: Pane::initialize(path),
    parents: [],
    history: Set([]),
    next_id: 1,
  }
}

///|
const PathHistoryLimit : Int32 = 64

///|
fn record_path_history(history : Set[String], path : Path) -> Set[String] {
  let path = path.to_string()
  guard !history.contains(path) else { return history }
  let updated = history.copy()
  if updated.length() >= PathHistoryLimit &&
    updated.iter().next() is Some(oldest) {
    updated.remove(oldest)
  }
  updated.add(path)
  updated
}

///|
fn PaneStack::navigate(stack : PaneStack, path : Path) -> PaneStack {
  let stack = { ..stack, history: record_path_history(stack.history, path), }
  guard path != stack.current.path else {
    return { ..stack, current: { ..stack.current, refresh_pending: true, }, }
  }
  if stack.parents.search_by(pane => pane.path == path) is Some(index) {
    return {
      ..stack,
      current: stack.parents[index],
      parents: stack.parents[:index].to_owned(),
    }
  }
  let parents = if !stack.current.path.to_string().is_empty() &&
    directory_contains(stack.current.path, path) {
    [..stack.parents, stack.current]
  } else {
    []
  }
  {
    ..stack,
    current: {
      ..Pane::initialize(path, id=stack.next_id),
      refresh_pending: true,
    },
    parents,
    next_id: stack.next_id + 1,
  }
}

///|
fn PaneStack::map_views(stack : PaneStack, f : (Pane) -> Pane) -> PaneStack {
  { ..stack, current: f(stack.current), parents: stack.parents.map(f), }
}

///|
fn PaneStack::invalidate(
  stack : PaneStack,
  affected : (Path) -> Bool,
) -> PaneStack {
  stack.map_views(pane => {
    ..pane,
    refresh_pending: pane.refresh_pending || affected(pane.path),
  })
}
