///|
/// Content is trusted embedded SVG.
pub(all) struct IconRegistry {
  /// Lowercase directory names, such as .git or _build.
  exact_folder : Map[String, String]
  /// Marker file names, such as .git or package.json.
  folder_icons : Map[String, String]
  dot_folder : String
  folder : String
  filenames : Map[String, String]
  /// Lowercase extensions without a leading dot; "" means no extension.
  extensions : Map[String, String]
  /// Receives the same normalized extension as extensions.
  rules : Array[(String) -> String?]
  unknown_file : String
}

///|
pub fn IconRegistry::for_entry(self : IconRegistry, entry : Entry) -> String {
  let name = entry.name.to_lower()
  guard !entry.is_dir else {
    match () {
      _ if self.exact_folder.get(name) is Some(content) => content
      _ if self.folder_icons.get(entry.marker) is Some(content) => content
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
  for rule in self.rules {
    guard rule(extension) is Some(content) else { continue }
    return content
  }
  self.unknown_file
}
