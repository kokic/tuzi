///|
/// Names identify one child, never a path supplied by a caller.
pub fn validate_entry_name(name : String) -> Unit raise FileError {
  guard !name.is_empty() &&
    name != "." &&
    name != ".." &&
    !name.contains("/") &&
    !name.contains("\u0000") &&
    (
      !(@async.platform is Windows) ||
      (!name.contains("\\") && !name.contains(":"))
    ) else {
    raise InvalidName(name)
  }
}

///|
/// Resolve parent aliases before comparing paths, without following the source entry.
async fn validate_transfer(from : Path, to : Path) -> Unit {
  let source = path_from_native(@async_fs.realpath(from.dirname().to_native())).join(
    Path("./\{from.basename()}"),
  )
  let destination = path_from_native(
    @async_fs.realpath(to.dirname().to_native()),
  ).join(Path("./\{to.basename()}"))
  let source_key = filesystem_path_key(source)
  for ancestor = destination {
    guard filesystem_path_key(ancestor) != source_key else {
      raise InvalidTarget(to)
    }
    let parent = ancestor.dirname()
    guard parent != ancestor else { break }
    continue parent
  }
}
