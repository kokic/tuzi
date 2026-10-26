///|
priv enum FileAction {
  DeleteOpen
  InfoOpen
  TransferSelection(TransferKind)
  CopyPaths
  RenameOpen
  ZipOpen
  NewEntryOpen
}

///|
priv struct FileActionContext {
  items : Array[OpenTarget]
  cursor : OpenTarget?
  directory : Path
  selection : SelectionSubmission?
}

///|
fn Model::file_action_context(model : Model) -> FileActionContext {
  let pane = model.pane_at(model.active)
  let target = (entry : Entry) => OpenTarget::{
    pane: model.active,
    path: pane.path.join(Path("./\{entry.name}")),
    entry,
  }
  let items = pane.selected_items()
  {
    items: items.map(target),
    cursor: pane.cursor_entry().map(target),
    directory: pane.path,
    selection: Some({
      pane: model.active,
      view_id: pane.id,
      selected: pane.selected,
      names: items.map(item => item.name),
    }),
  }
}

///|
fn Model::execute_entry_action(
  model : Model,
  idx : PaneSide,
  view_id : Int32,
  name : String,
  action : FileAction,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let pane = model.pane_at(idx)
  guard pane.id == view_id &&
    pane.visible_entries.any(entry => entry.name == name) else {
    return (model, @rabbita.none)
  }
  let pane = {
    ..pane,
    cursor: Some(name),
    selected: if pane.selected.contains(name) {
      pane.selected
    } else {
      Set([])
    },
  }
  let model = { ..model, active: idx, panes: set_pane(model.panes, idx, pane), }
  model.execute_file_action(action, model.file_action_context(), emit)
}

///|
fn Model::execute_file_action(
  model : Model,
  action : FileAction,
  context : FileActionContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  match action {
    DeleteOpen => (model.open_delete_dialog(context), @rabbita.none)
    InfoOpen =>
      context.cursor.map_or((model, @rabbita.none), target => {
        model.open_info_dialog(target, emit)
      })
    TransferSelection(kind) =>
      model.transfer_selection_to_other_pane(kind, context, emit)
    CopyPaths => model.copy_selected_paths_to_clipboard(context, emit)
    RenameOpen => model.open_rename_dialog(context, emit)
    ZipOpen => (model.open_archive_dialog(context), @rabbita.none)
    NewEntryOpen =>
      (model.open_new_entry_dialog(context.directory), @rabbita.none)
  }
}
