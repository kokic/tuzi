///|
/// Capture operation targets when opening, so later pane updates cannot retarget it.
fn Model::open_delete_dialog(model : Model) -> Model {
  let pane = model.pane_at(model.active)
  let items = pane.selected_items(filter?=model.entry_filter(model.active))
  guard !items.is_empty() else { return model }
  {
    ..model,
    dialog: DeleteConfirm(
      directory=pane.path,
      names=items.map(item => item.name),
    ),
    dialog_error: "",
  }
}

///|
fn Model::open_rename_dialog(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  let pane = model.pane_at(model.active)
  guard pane.selected_entry(filter?=model.entry_filter(model.active))
    is Some(item) else {
    return (
      model,
      emit(Toast("Select one item to rename", None, @rui.ToastDefault)),
    )
  }
  guard !item.is_link() else {
    return (
      model,
      emit(
        Toast(
          "Edit the link path and target in Information",
          None,
          @rui.ToastDefault,
        ),
      ),
    )
  }
  (
    {
      ..model,
      dialog: RenameInput(
        directory=pane.path,
        original=item.name,
        input=item.name,
      ),
      dialog_error: "",
    },
    @rabbita.none,
  )
}

///|
fn Model::open_archive_dialog(model : Model) -> Model {
  let pane = model.pane_at(model.active)
  let items = pane.selected_items(filter?=model.entry_filter(model.active))
  guard !items.is_empty() else { return model }
  {
    ..model,
    dialog: ZipInput(
      directory=pane.path,
      names=items.map(item => item.name),
      input=default_archive_name(items, pane.path),
      level=6,
    ),
    dialog_error: "",
  }
}

///|
fn Model::open_new_entry_dialog(model : Model) -> Model {
  {
    ..model,
    dialog: NewEntryInput(directory=model.pane_at(model.active).path, input=""),
    dialog_error: "",
  }
}

///|
fn Dialog::with_input(self : Dialog, input : String) -> Dialog {
  match self {
    RenameInput(directory~, original~, ..) =>
      RenameInput(directory~, original~, input~)
    ZipInput(directory~, names~, level~, ..) =>
      ZipInput(directory~, names~, input~, level~)
    UnzipInput(source~, ..) => UnzipInput(source~, input~)
    NewEntryInput(directory~, ..) => NewEntryInput(directory~, input~)
    GitRenameInput(context~, reference~, ..) =>
      GitRenameInput(context~, reference~, input~)
    None
    | Help
    | Activity
    | Bookmarks(_)
    | TaskDetails(_)
    | TaskOutput(_)
    | Info(_)
    | Markdown(_)
    | GitInfo(_)
    | Progress(_)
    | DeleteConfirm(..) => self
  }
}

///|
fn Model::set_archive_compression_level(
  model : Model,
  value : String,
) -> (Model, Cmd) {
  guard model.dialog is ZipInput(directory~, names~, input~, ..) else {
    return (model, @rabbita.none)
  }
  let level = @string.parse_int(value, base=10) catch {
    _ => return (model, @rabbita.none)
  }
  guard level >= 0 && level <= 9 else { return (model, @rabbita.none) }
  (
    {
      ..model,
      dialog: ZipInput(directory~, names~, input~, level~),
      dialog_error: "",
    },
    @rabbita.none,
  )
}

///|
fn Model::cancel_dialog(model : Model) -> (Model, Cmd) {
  // The native dialog has already closed and raised its close event. Going
  // back to the Git panel keeps a dialog open, so reopen the host element.
  let dialog = match model.dialog {
    GitRenameInput(context~, ..) => GitInfo(context)
    _ => None
  }
  let command = if dialog is GitInfo(_) {
    @dialog.show(DialogId)
  } else {
    @rabbita.none
  }
  ({ ..model, dialog, dialog_error: "", }, command)
}
