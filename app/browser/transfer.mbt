///|
priv struct SelectionSubmission {
  pane : PaneSide
  view_id : Int
  selected : Set[String]
  names : Array[String]
}

///|
/// Replies only clear accepted entries from an unchanged selection in its original view.
fn Model::clear_accepted_selection(
  model : Model,
  context : SelectionSubmission,
  result : Result[@tuzi.TaskSubmission, RequestFailure],
) -> Model {
  guard result is Ok(submission) else { return model }
  let clear = (pane : Pane) => {
    guard pane.id == context.view_id && pane.selected == context.selected else {
      return pane
    }
    let selected = pane.selected.copy()
    submission.results.eachi((index, result) => {
      if result is Success(_) {
        selected.remove(context.names[index])
      }
    })
    { ..pane, selected, }
  }
  {
    ..model,
    panes: match context.pane {
      Left => (model.panes.0.map_views(clear), model.panes.1)
      Right => (model.panes.0, model.panes.1.map_views(clear))
    },
  }
}

///|
fn Model::transfer_selection_to_other_pane(
  model : Model,
  kind : TransferKind,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let src = model.pane_at(model.active)
  let dst = model.pane_at(model.active.other())
  guard src.path != dst.path else { return (model, @rabbita.none) }
  let items = src.selected_items(filter?=model.entry_filter(model.active))
  guard !items.is_empty() else { return (model, @rabbita.none) }
  guard !(kind is Move && items.any(entry => entry.kind.is_link())) else {
    return (
      model,
      emit(Toast("Edit the link path in Information", None, @rui.ToastDefault)),
    )
  }
  let operations = items.map(entry => {
    let from = src.path.join(Path("./\{entry.name}"))
    let to = dst.path.join(Path("./\{entry.name}"))
    kind.operation(from, to)
  })
  model
  .start_file_operations(operations, emit, selection={
    pane: model.active,
    view_id: src.id,
    selected: src.selected,
    names: items.map(item => item.name),
  })
  .unwrap_or((model, @rabbita.none))
}

///|
fn Model::copy_dropped_entries(
  model : Model,
  idx : PaneSide,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.dragging is Some(selection) && selection.source_pane != idx else {
    return (model, @rabbita.none)
  }
  let dst = model.pane_at(idx)
  let operations = selection.names.map(name => {
    FileOperation::Copy(
      source=selection.directory.join(Path("./\{name}")),
      destination=dst.path.join(Path("./\{name}")),
    )
  })
  let (updated, command) = model
    .start_file_operations(operations, emit)
    .unwrap_or((model, @rabbita.none))
  ({ ..updated, dragging: None, }, command)
}

///|
fn TransferKind::operation(
  kind : TransferKind,
  source : Path,
  destination : Path,
) -> FileOperation {
  match kind {
    Copy => Copy(source~, destination~)
    Move => Move(source~, destination~)
  }
}

///|
priv enum TransferKind {
  Copy
  Move
}

///|
priv struct DragSelection {
  source_pane : PaneSide
  directory : Path
  names : Array[String]
} derive(Eq)

///|
fn Model::start_entry_drag(
  model : Model,
  idx : PaneSide,
  name : String,
) -> (Model, Cmd) {
  let pane = model.pane_at(idx)
  let names = if pane.selected.contains(name) {
    pane
    .selected_items(filter?=model.entry_filter(idx))
    .map(entry => entry.name)
  } else {
    [name]
  }
  (
    {
      ..model,
      dragging: Some({ source_pane: idx, directory: pane.path, names, }),
    },
    @rabbita.none,
  )
}
