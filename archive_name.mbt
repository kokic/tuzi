///|
/// Choose a default ZIP name: `a.txt -> a.zip`, `a.zip -> a.zip`, dir/multi -> `<dir>.zip`.
pub fn default_archive_name(items : Array[Entry], directory : Path) -> String {
  let name = {
    guard items.length() == 1 else { directory.basename() }
    let item = items[0]
    guard !item.is_dir() && item.name.rev_find(".") is Some(dot) && dot > 0 else {
      item.name
    }
    item.name.view(end_offset=dot).to_owned()
  }
  guard !name.is_empty() else { "archive.zip" }
  name + ".zip"
}

///|
/// Whether a name is a single archive path component. Rejects empty names,
/// dot segments, separators, colons, and NUL on every host platform.
pub fn is_valid_archive_name(name : String) -> Bool {
  !name.is_empty() &&
  name != "." &&
  name != ".." &&
  !name.contains("/") &&
  !name.contains("\\") &&
  !name.contains(":") &&
  !name.contains("\u0000")
}
