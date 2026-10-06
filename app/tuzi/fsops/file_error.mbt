///|
pub suberror FileError {
  InvalidName(String)
  InvalidTarget(Path)
  UnsupportedEntry(String)
  CleanupFailed(Path, Error)
  SourceRemovalFailed(Path, Path, Error)
}

///|
pub extend FileError with Show::{to_string, output}

///|
pub impl Show for FileError with fn to_string(self) {
  match self {
    InvalidName(name) => "Invalid name: " + name
    InvalidTarget(path) =>
      "Destination must not be the source or inside it: \{path}"
    UnsupportedEntry(path) => "Unsupported entry: " + path
    CleanupFailed(path, error) =>
      "Could not remove incomplete output at \{path}: \{error}"
    SourceRemovalFailed(source, destination, error) =>
      "Copied to \{destination}, but could not fully remove \{source}: \{error}"
  }
}
