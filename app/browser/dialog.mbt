///|
/// Capture operation targets when opening, so later pane updates cannot retarget it.
fn Model::open_delete_dialog(
  model : Model,
  context : FileActionContext,
) -> Model {
  let items = context.items
  guard !items.is_empty() else { return model }
  {
    ..model,
    dialog: DeleteConfirm(
      directory=items[0].path.dirname(),
      names=items.map(item => item.entry.name),
    ),
    dialog_error: "",
  }
}

///|
fn Model::open_rename_dialog(
  model : Model,
  context : FileActionContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard context.items.length() == 1 else {
    return (
      model,
      emit(Toast("Select one item to rename", None, @rui.ToastDefault)),
    )
  }
  let target = context.items[0]
  let item = target.entry
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
        directory=target.path.dirname(),
        original=item.name,
        input=item.name,
      ),
      dialog_error: "",
    },
    @rabbita.none,
  )
}

///|
fn Model::open_archive_dialog(
  model : Model,
  context : FileActionContext,
) -> Model {
  let items = context.items
  guard !items.is_empty() else { return model }
  {
    ..model,
    dialog: ZipInput(
      directory=items[0].path.dirname(),
      names=items.map(item => item.entry.name),
      input=default_archive_name(
        items.map(item => item.entry),
        items[0].path.dirname(),
      ),
      level=6,
    ),
    dialog_error: "",
  }
}

///|
fn Model::open_new_entry_dialog(model : Model, directory : Path) -> Model {
  { ..model, dialog: NewEntryInput(directory~, input=""), dialog_error: "", }
}

///|
fn Dialog::with_input(self : Dialog, input : String) -> Dialog {
  match self {
    Goto(context) => Goto({ ..context, input, pending: false, })
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
    | BookmarkDeleteConfirm(..)
    | TaskDetails(_)
    | TaskOutput(_)
    | Info(_)
    | Markdown(_)
    | TextPreview(_)
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
  // back to a parent panel keeps a dialog open, so reopen the host element.
  let dialog = match model.dialog {
    GitRenameInput(context~, ..) => GitInfo(context)
    BookmarkDeleteConfirm(side~, ..) => Bookmarks(side)
    _ => None
  }
  let command = if dialog != None {
    @dialog.show(DialogId)
  } else {
    @rabbita.none
  }
  ({ ..model, dialog, dialog_error: "", }, command)
}
