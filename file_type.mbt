///|
/// Returns a lowercase type suffix including the leading dot, or an empty string.
/// Dotfiles such as `.md` use their whole name as the suffix; `.` and `..` do not.
fn file_type_suffix(name : String) -> String {
  let name = name.to_lower()
  let suffix = @posix.Path(name).extname().to_owned()
  if suffix.is_empty() && name.has_prefix(".") && name != "." && name != ".." {
    name
  } else {
    suffix
  }
}
