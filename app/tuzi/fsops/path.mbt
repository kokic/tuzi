///|
using @uniform_path {type Path}

///|
pub fn path_from_native(input : String) -> Path {
  guard @async.platform is Windows else { return Path(input) }
  Path::from_windows(input)
}

///|
pub fn filesystem_path_key(path : Path) -> String {
  let text = path.to_string()
  guard @async.platform is Windows else { return text }
  text.to_lower()
}
