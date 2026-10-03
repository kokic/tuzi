///|
/// Names identify one child, never a path supplied by a caller.
fn validate_entry_name(name : String) -> Unit raise FileError {
  guard !name.is_empty() &&
    name != "." &&
    name != ".." &&
    !name.contains("/") &&
    !name.contains("\u0000") &&
    (@path.sep != '\\' || (!name.contains("\\") && !name.contains(":"))) else {
    raise InvalidName(name)
  }
}

///|
/// Check only request data; filesystem state is checked when the task executes.
fn validate_file_operation_input(
  operation : @shared.FileOperation,
) -> Unit raise {
  match operation {
    Delete(target~) => validate_entry_name(target.basename())
    Rename(source~, new_name~) => {
      validate_entry_name(source.basename())
      validate_entry_name(new_name)
    }
    EditLink(source~, destination~, target~) => {
      validate_link_path(source)
      validate_link_path(destination)
      validate_link_target(target)
    }
    CreateFile(name~, ..) | Mkdir(name~, ..) => validate_entry_name(name)
    Zip(names~, output_name~, level~, ..) =>
      validate_zip_selection(names, output_name, level~)
    Unzip(source~, destination~) => {
      validate_entry_name(source.basename())
      validate_entry_name(destination.basename())
    }
    Copy(source~, destination~) | Move(source~, destination~) => {
      validate_entry_name(source.basename())
      validate_entry_name(destination.basename())
    }
  }
}

///|
/// Resolve parent aliases before comparing paths, without following the source entry.
async fn validate_transfer(from : Path, to : Path) -> Unit {
  let source = Path::from_native(@async_fs.realpath(from.dirname().to_string())).join(
    Path("./\{from.basename()}"),
  )
  let destination = Path::from_native(
    @async_fs.realpath(to.dirname().to_string()),
  ).join(Path("./\{to.basename()}"))
  let source_key = filesystem_path_key(source)
  for ancestor = destination {
    guard filesystem_path_key(ancestor) != source_key else {
      raise InvalidTarget(
        "Destination must not be the source or inside it: \{to}",
      )
    }
    let parent = ancestor.dirname()
    guard parent != ancestor else { break }
    continue parent
  }
}

///|
fn filesystem_path_key(path : Path) -> String {
  let text = path.to_string()
  if @path.sep == '\\' {
    text.to_lower()
  } else {
    text
  }
}
