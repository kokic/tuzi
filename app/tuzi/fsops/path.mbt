///|
using @uniform_path {type Path}

///|
/// Filesystem APIs return host syntax; the protocol uses uniform syntax.
pub fn path_from_native(input : String) -> Path {
  if @path.sep == '\\' {
    Path::from_windows(input)
  } else {
    Path(input)
  }
}

///|
pub fn filesystem_path_key(path : Path) -> String {
  let text = path.to_string()
  if @path.sep == '\\' {
    text.to_lower()
  } else {
    text
  }
}
