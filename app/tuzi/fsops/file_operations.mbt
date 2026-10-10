///|
pub async fn remove_entry(target : Path) -> Unit {
  remove_path(target)
}

///|
pub async fn rename_entry(source : Path, new_name : String) -> Unit {
  let old_name = source.basename()
  guard old_name != new_name else { return }
  rename_path(source, source.dirname().join(Path("./\{new_name}")))
}

///|
/// Renaming and moving links are not supported file operations.
async fn rename_path(from : Path, to : Path) -> Unit {
  let source = from.to_native()
  guard !(@async_fs.kind(source, follow_symlink=false) is SymLink) else {
    raise FileError::UnsupportedEntry(source)
  }
  @async_fs.rename(source, to.to_native(), replace=false)
}

///|
pub async fn mkdir_entry(path : Path, name : String) -> Unit {
  @async_fs.mkdir(path.join(Path("./\{name}")).to_native())
}

///|
pub async fn create_file_entry(path : Path, name : String) -> Unit {
  let file = @async_fs.create(
    path.join(Path("./\{name}")).to_native(),
    allow_existing=false,
  )
  file.close()
}
