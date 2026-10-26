///|
using @path {type Path}

///|
pub fn default_archive_name(items : Array[Entry], directory : Path) -> String {
  let name = {
    guard items.length() == 1 else { directory.basename() }
    let item = items[0]
    guard item.kind is Ok(kind) &&
      !kind.is_dir() &&
      item.name.rev_find(".") is Some(dot) &&
      dot > 0 else {
      item.name
    }
    item.name.view(end_offset=dot).to_owned()
  }
  guard !name.is_empty() else { "archive.zip" }
  name + ".zip"
}
