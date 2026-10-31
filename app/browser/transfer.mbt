///|
priv struct SelectionSubmission {
  pane : PaneSide
  view_id : Int32
  selected : Set[String]
  names : Array[String]
}

///|
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
  context : FileActionContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let dst = model.pane_at(model.active.other())
  let items = context.items
  guard items.all(item => item.path.dirname() != dst.path) else {
    return (model, @rabbita.none)
  }
  guard !items.is_empty() else { return (model, @rabbita.none) }
  guard !(kind is Move && items.any(item => item.entry.is_link())) else {
    return (
      model,
      emit(Toast("Edit the link path in Information", None, @rui.ToastDefault)),
    )
  }
  let operations = items.map(item => {
    let to = dst.path.join(Path("./\{item.entry.name}"))
    kind.operation(item.path, to)
  })
  model
  .start_file_operations(operations, emit, selection?=context.selection)
  .unwrap_or((model, @rabbita.none))
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
