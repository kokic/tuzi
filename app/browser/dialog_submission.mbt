///|
priv suberror DialogInputError {
  NameRequired
  InvalidArchiveSelection
  DestinationRequired
}

///|
impl Show for DialogInputError with fn to_string(self) {
  match self {
    NameRequired => "Name is required"
    InvalidArchiveSelection => "A selected entry has an invalid archive name"
    DestinationRequired => "Destination directory is required"
  }
}

///|
/// Keep input intact; filesystem conflicts are decided by the server at execution.
fn validate_dialog_name(input : String) -> String raise DialogInputError {
  guard !input.is_empty() else { raise NameRequired }
  input
}

///|
fn Dialog::file_operations(
  self : Dialog,
  new_entry_kind : NewEntryKind,
) -> Array[FileOperation]? raise {
  let operations = match self {
    DeleteConfirm(directory~, names~) =>
      names.map(name => {
        FileOperation::Delete(target=directory.join(Path("./\{name}")))
      })
    RenameInput(directory~, original~, input~) => {
      let name = validate_dialog_name(input)
      [
        FileOperation::Rename(
          source=directory.join(Path("./\{original}")),
          new_name=name,
        ),
      ]
    }
    ZipInput(directory~, names~, input~, level~) => {
      let name = validate_dialog_name(input)
      guard names.all(name => @tuzi.is_valid_archive_name(name)) else {
        raise InvalidArchiveSelection
      }
      [FileOperation::Zip(directory~, names~, output_name=name, level~)]
    }
    UnzipInput(source~, input~) => {
      guard !input.is_empty() else { raise DestinationRequired }
      let destination = source.dirname().resolve(Path(input))
      [FileOperation::Unzip(source~, destination~)]
    }
    NewEntryInput(directory~, input~) => {
      let name = validate_dialog_name(input)
      [
        match new_entry_kind {
          File => FileOperation::CreateFile(parent=directory, name~)
          Folder => FileOperation::Mkdir(parent=directory, name~)
        },
      ]
    }
    None
    | Help
    | Activity
    | TaskDetails(_)
    | Markdown(_)
    | Progress(_)
    | Info(_)
    | GitInfo(_)
    | GitRenameInput(..) => return None
  }
  Some(operations)
}

///|
fn Model::submit_dialog(
  model : Model,
  emit : Emit[Msg],
  new_entry_kind? : NewEntryKind = Folder,
) -> (Model, Cmd) {
  match model.dialog {
    Info(context) => return model.submit_info_link(context, emit)
    GitInfo(context) => return model.submit_info_link(context.entry, emit)
    GitRenameInput(context~, reference~, input~) =>
      return model.submit_git_rename(context, reference, input, emit)
    _ => ()
  }
  let operations = model.dialog.file_operations(new_entry_kind) catch {
    error =>
      return ({ ..model, dialog_error: error.to_string(), }, @rabbita.none)
  }
  guard operations is Some(operations) else { return (model, @rabbita.none) }
  let input_dialog = match model.dialog {
    RenameInput(..) | ZipInput(..) | UnzipInput(..) | NewEntryInput(..) =>
      Some(model.dialog)
    _ => None
  }
  model
  .start_file_operations(operations, emit, input_dialog?)
  .unwrap_or((model, @rabbita.none))
}
