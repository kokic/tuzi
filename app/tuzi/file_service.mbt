///|
priv suberror FileError {
  InvalidName(String)
  InvalidTarget(String)
  UnsupportedEntry(String)
  PartialFailure(String)
}

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
async fn remove_entry(target : Path) -> Unit {
  remove_path(target)
}

///|
async fn rename_entry(source : Path, new_name : String) -> Unit {
  let old_name = source.basename()
  guard old_name != new_name else { return }
  @async_fs.rename(
    source.to_string(),
    source.dirname().join(Path("./\{new_name}")).to_string(),
    replace=false,
  )
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

///|
async fn copy_entry(from : Path, to : Path) -> Unit {
  validate_transfer(from, to)
  copy_tree(from, to)
}

///|
/// Only regular files and directories are copied; links are never dereferenced.
/// Exclusive creation means cleanup only removes output owned by this operation.
async fn copy_tree(from : Path, to : Path) -> Unit {
  let kind = @async_fs.kind(from.to_string(), follow_symlink=false)
  match kind {
    Directory => {
      @async_fs.mkdir(to.to_string())
      errdefer cleanup_copy(to)
      let dir = @async_fs.opendir(from.to_string())
      defer dir.close()
      while dir.next(include_hidden=true, include_special=false) is Some(entry) {
        let child = Path("./\{entry.name}")
        copy_tree(from.join(child), to.join(child))
      }
    }
    Regular => copy_file(from, to)
    _ => raise FileError::UnsupportedEntry(from.to_string())
  }
}

///|
async fn cleanup_copy(path : Path) -> Unit nocancel {
  @async.protect_from_cancel(() => {
    remove_path(path) catch {
      error =>
        raise PartialFailure(
          "Could not remove incomplete output at \{path}: \{error}",
        )
    }
  })
}

///|
async fn copy_file(from : Path, to : Path) -> Unit {
  let src = @async_fs.open(from.to_string(), mode=ReadOnly)
  defer src.close()
  let dst = @async_fs.create(to.to_string(), allow_existing=false)
  defer dst.close()
  errdefer {
    dst.close()
    cleanup_copy(to)
  }
  while src.read_some(max_len=64 * 1024) is Some(data) {
    dst.write(data)
    @async.pause()
  }
}

///|
extern "C" fn is_cross_device_error(code : Int) -> Bool = "tuzi_is_cross_device_error"

///|
async fn move_entry(from : Path, to : Path) -> Unit {
  validate_transfer(from, to)
  @async_fs.rename(from.to_string(), to.to_string(), replace=false) catch {
    @os_error.OSError(code, ..) as error => {
      guard is_cross_device_error(code) else { raise error }
      copy_tree(from, to)
      remove_path(from) catch {
        error =>
          raise PartialFailure(
            "Copied to \{to}, but could not fully remove \{from}: \{error}",
          )
      }
    }
    error => raise error
  }
}

///|
async fn execute_file_operation(operation : @shared.FileOperation) -> Unit {
  match operation {
    Delete(target~) => remove_entry(target)
    Rename(source~, new_name~) => rename_entry(source, new_name)
    CreateFile(parent~, name~) => create_file_entry(parent, name)
    Mkdir(parent~, name~) => mkdir_entry(parent, name)
    Zip(directory~, names~, output_name~, level~) =>
      zip_entries(directory, names, output_name, level~)
    Unzip(source~, destination~) => unzip_entries(source, destination)
    Copy(source~, destination~) => copy_entry(source, destination)
    Move(source~, destination~) => move_entry(source, destination)
  }
}
