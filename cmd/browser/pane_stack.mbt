///|
/// Each mounted directory owns its listing and DOM for the lifetime of this
/// stack entry. IDs are never reused, including after an entry is popped.
priv struct PaneStack {
  current : Pane
  parents : Array[Pane]
  next_id : Int
} derive(Eq)

///|
fn PaneStack::initialize(path : Path) -> PaneStack {
  { current: Pane::initialize(path), parents: [], next_id: 1, }
}

///|
fn PaneStack::navigate(stack : PaneStack, path : Path) -> PaneStack {
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
