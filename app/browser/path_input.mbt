///|
/// User-entered paths use one syntax on every platform: both `/` and `\`
/// are path separators, never literal characters in file names.
fn parse_user_path(input : String) -> Path {
  Path::from_windows(input)
}
