///|
/// File and directory matching rules for filename colors.
priv struct EntryColorRegistry {
  /// Lowercase directory names, such as .git or _build.
  exact_folder : Map[String, String]
  /// Marker file names, such as .git or package.json.
  marker_colors : Map[String, String]
  dot_folder : String
  folder : String
  filenames : Map[String, String]
  /// Lowercase extensions without a leading dot; "" means no extension.
  extensions : Map[String, String]
  unknown_file : String
}

///|
fn EntryColorRegistry::for_entry(
  self : EntryColorRegistry,
  entry : Entry,
) -> String {
  let name = entry.name.to_lower()
  guard !entry.is_dir else {
    return match () {
      _ if self.exact_folder.get(name) is Some(content) => content
      _ if self.marker_colors.get(entry.marker) is Some(content) => content
      _ if entry.name.has_prefix(".") => self.dot_folder
      _ => self.folder
    }
  }

  if self.filenames.get(name) is Some(content) {
    return content
  }
  let raw_extension = @posix.Path(name).extname().to_owned()

  // Names without an extension, including dotfiles such as .txt, try a filename-based key.
  if raw_extension == "" {
    let key = name.strip_prefix(".").map_or(name, suffix => suffix.to_owned())
    if self.extensions.get(key) is Some(content) {
      return content
    }
  }

  let extension = raw_extension
    .strip_prefix(".")
    .map_or("", suffix => suffix.to_owned())
  if self.extensions.get(extension) is Some(content) {
    return content
  }
  self.unknown_file
}

///|
pub fn entry_color(entry : Entry, mode : IconMode) -> String {
  match mode {
    None => "currentColor"
    Svg => builtin_entry_colors.for_entry(entry)
  }
}
