///|
/// Capture operation targets when opening, so later pane updates cannot retarget it.
fn Model::open_delete_dialog(model : Model) -> Model {
  let pane = model.pane_at(model.active)
  let items = pane.selected_items(filter?=model.entry_filter())
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
  guard pane.selected_entry(filter?=model.entry_filter()) is Some(item) else {
    return (
      model,
      emit(Toast("Select one item to rename", None, @rui.ToastDefault)),
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
  let items = pane.selected_items(filter?=model.entry_filter())
  guard !items.is_empty() else { return model }
  {
    ..model,
    dialog: ZipInput(
      directory=pane.path,
      names=items.map(item => item.name),
      input=default_archive_name(items, pane.path),
    ),
    dialog_error: "",
  }
}

///|
fn Dialog::with_input(self : Dialog, input : String) -> Dialog {
  match self {
    RenameInput(directory~, original~, ..) =>
      RenameInput(directory~, original~, input~)
    ZipInput(directory~, names~, ..) => ZipInput(directory~, names~, input~)
    MkdirInput(directory~, ..) => MkdirInput(directory~, input~)
    GitRenameInput(context~, reference~, ..) =>
      GitRenameInput(context~, reference~, input~)
    None
    | Help
    | Activity
    | TaskDetails(_)
    | Info(_)
    | GitInfo(_)
    | Progress(_)
    | DeleteConfirm(..) => self
  }
}

///|
/// Keep input intact; filesystem conflicts are decided by the server at execution.
fn validate_dialog_name(input : String) -> Result[String, String] {
  let name = input
  guard !name.is_empty() else { return Err("Name is required") }
  Ok(name)
}

///|
fn Model::submit_dialog(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  let operations = match model.dialog {
    GitRenameInput(context~, reference~, input~) =>
      return model.submit_git_rename(context, reference, input, emit)
    DeleteConfirm(directory~, names~) =>
      Ok(
        names.map(name => {
          FileOperation::Delete(target=directory.join(Path("./\{name}")))
        }),
      )
    RenameInput(directory~, original~, input~) =>
      validate_dialog_name(input).map(name => {
        [
          FileOperation::Rename(
            source=directory.join(Path("./\{original}")),
            new_name=name,
          ),
        ]
      })
    ZipInput(directory~, names~, input~) =>
      match validate_dialog_name(input) {
        Err(message) => Err(message)
        Ok(name) => {
          guard names.all(name => @tuzi.is_valid_archive_name(name)) else {
            Err("A selected entry has an invalid archive name")
          }
          Ok([FileOperation::Zip(directory~, names~, output_name=name)])
        }
      }
    MkdirInput(directory~, input~) =>
      validate_dialog_name(input).map(name => {
        [FileOperation::Mkdir(parent=directory, name~)]
      })
    None
    | Help
    | Activity
    | TaskDetails(_)
    | Info(_)
    | GitInfo(_)
    | Progress(_) => return (model, @rabbita.none)
  }
  match operations {
    Err(message) => ({ ..model, dialog_error: message, }, @rabbita.none)
    Ok(operations) => {
      let input_dialog = match model.dialog {
        RenameInput(..) | ZipInput(..) | MkdirInput(..) => Some(model.dialog)
        _ => None
      }
      model
      .start_file_operations(operations, emit, input_dialog?)
      .unwrap_or((model, @rabbita.none))
    }
  }
}
