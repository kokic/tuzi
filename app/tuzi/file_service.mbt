///|
priv suberror FileError {
  InvalidName(String)
  InvalidTarget(Path)
  UnsupportedEntry(String)
  CleanupFailed(Path, Error)
  SourceRemovalFailed(Path, Path, Error)
}

///|
impl Show for FileError with fn to_string(self) {
  match self {
    InvalidName(name) => "Invalid name: " + name
    InvalidTarget(path) =>
      "Destination must not be the source or inside it: \{path}"
    UnsupportedEntry(path) => "Unsupported entry: " + path
    CleanupFailed(path, error) =>
      "Could not remove incomplete output at \{path}: \{error}"
    SourceRemovalFailed(source, destination, error) =>
      "Copied to \{destination}, but could not fully remove \{source}: \{error}"
  }
}

///|
async fn remove_entry(target : Path) -> Unit {
  remove_path(target)
}

///|
async fn rename_entry(source : Path, new_name : String) -> Unit {
  let old_name = source.basename()
  guard old_name != new_name else { return }
  rename_path(source, source.dirname().join(Path("./\{new_name}")))
}

///|
/// Renaming and moving links are not supported file operations.
async fn rename_path(from : Path, to : Path) -> Unit {
  let source = from.to_string()
  guard !(@async_fs.kind(source, follow_symlink=false) is SymLink) else {
    raise FileError::UnsupportedEntry(source)
  }
  @async_fs.rename(source, to.to_string(), replace=false)
}

///|
async fn mkdir_entry(path : Path, name : String) -> Unit {
  @async_fs.mkdir(path.join(Path("./\{name}")).to_string())
}

///|
async fn create_file_entry(path : Path, name : String) -> Unit {
  let file = @async_fs.create(
    path.join(Path("./\{name}")).to_string(),
    allow_existing=false,
  )
  file.close()
}

///|
async fn execute_file_operation(operation : @shared.FileOperation) -> Unit {
  match operation {
    Delete(target~) => remove_entry(target)
    Rename(source~, new_name~) => rename_entry(source, new_name)
    EditLink(source~, destination~, target~) =>
      edit_link(source, destination, target)
    CreateFile(parent~, name~) => create_file_entry(parent, name)
    Mkdir(parent~, name~) => mkdir_entry(parent, name)
    Zip(directory~, names~, output_name~, level~) =>
      zip_entries(directory, names, output_name, level~)
    Unzip(source~, destination~) => unzip_entries(source, destination)
    Copy(source~, destination~) => copy_entry(source, destination)
    Move(source~, destination~) => move_entry(source, destination)
  }
}
