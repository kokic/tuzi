///|
pub fn is_valid_archive_name(name : String) -> Bool {
  !name.is_empty() &&
  name != "." &&
  name != ".." &&
  !name.contains("/") &&
  !name.contains("\\") &&
  !name.contains(":") &&
  !name.contains("\u0000")
}
