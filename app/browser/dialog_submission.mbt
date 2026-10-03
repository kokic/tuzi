///|
/// Keep input intact; filesystem conflicts are decided by the server at execution.
fn validate_dialog_name(input : String) -> Result[String, String] {
  let name = input
  guard !name.is_empty() else { return Err("Name is required") }
  Ok(name)
}

///|
fn Model::submit_dialog(
  model : Model,
  emit : Emit[Msg],
  new_entry_kind? : NewEntryKind = Folder,
) -> (Model, Cmd) {
  let operations = match model.dialog {
    Info(context) => return model.submit_info_link(context, emit)
    GitInfo(context) => return model.submit_info_link(context.entry, emit)
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
    ZipInput(directory~, names~, input~, level~) =>
      match validate_dialog_name(input) {
        Err(message) => Err(message)
        Ok(name) => {
          guard names.all(name => @tuzi.is_valid_archive_name(name)) else {
            Err("A selected entry has an invalid archive name")
          }
          Ok([FileOperation::Zip(directory~, names~, output_name=name, level~)])
        }
      }
    UnzipInput(source~, input~) => {
      guard !input.is_empty() else { Err("Destination directory is required") }
      try {
        let destination = source.dirname().resolve(Path(input))
        Ok([FileOperation::Unzip(source~, destination~)])
      } catch {
        error => Err(error.to_string())
      }
    }
    NewEntryInput(directory~, input~) =>
      validate_dialog_name(input).map(name => {
        [
          match new_entry_kind {
            File => FileOperation::CreateFile(parent=directory, name~)
            Folder => FileOperation::Mkdir(parent=directory, name~)
          },
        ]
      })
    None | Help | Activity | TaskDetails(_) | Markdown(_) | Progress(_) =>
      return (model, @rabbita.none)
  }
  match operations {
    Err(message) => ({ ..model, dialog_error: message, }, @rabbita.none)
    Ok(operations) => {
      let input_dialog = match model.dialog {
        RenameInput(..) | ZipInput(..) | UnzipInput(..) | NewEntryInput(..) =>
          Some(model.dialog)
        _ => None
      }
      model
      .start_file_operations(operations, emit, input_dialog?)
      .unwrap_or((model, @rabbita.none))
    }
  }
}
