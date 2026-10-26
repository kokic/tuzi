///|
priv struct EntryColorRegistry {
  exact_folder : Map[String, String]
  marker_colors : Map[String, String]
  dot_folder : String
  folder : String
  filenames : Map[String, String]
  extensions : Map[String, String]
  unknown_file : String
}

///|
fn EntryColorRegistry::for_entry(
  self : EntryColorRegistry,
  entry : Entry,
) -> String {
  guard entry.kind is Ok(_) else { return "currentColor" }
  let name = entry.name.to_lower()
  guard !entry.is_dir() else {
    return match () {
      _ if self.exact_folder.get(name) is Some(content) => content
      _ if entry.marker is Ok(marker) &&
        self.marker_colors.get(marker) is Some(content) => content
      _ if entry.name.has_prefix(".") => self.dot_folder
      _ => self.folder
    }
  }

  if self.filenames.get(name) is Some(content) {
    return content
  }
  let raw_extension = @posix.Path(name).extname().to_owned()

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
pub fn entry_color(entry : Entry, mode : EntryAppearance) -> String {
  match mode {
    Plain => "currentColor"
    Decorated => builtin_entry_colors.for_entry(entry)
  }
}
