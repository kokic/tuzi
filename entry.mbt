///|
pub(all) enum EntryKind {
  Regular
  Directory
  /// A symbolic link or Windows junction, carrying its final absolute target.
  SymbolicLink(Path, EntryKind)
  /// The link exists, but its target could not be resolved or inspected.
  UnresolvedLink(ApiFailure)
  Socket
  Pipe
  BlockDevice
  CharDevice
  Unknown
} derive(Eq, FromJson, ToJson)

///|
pub extend EntryKind with Eq::{equal, not_equal}

///|
pub extend EntryKind with FromJson::{from_json}

///|
pub extend EntryKind with ToJson::{to_json}

///|
pub(all) struct Entry {
  name : String
  /// Entry type, or the failure to inspect this entry.
  kind : Result[EntryKind, ApiFailure]
  /// File size in bytes; Ok(None) for directories, Err for failed reads.
  size : Result[Int64?, ApiFailure]
  /// Modification time in Unix seconds, or the metadata read failure.
  mtime : Result[Int64, ApiFailure]
  /// The first name in `folder_markers` found directly inside this directory,
  /// Ok("") when none, disabled, or not a directory; Err for failed detection.
  marker : Result[String, ApiFailure]
} derive(Eq, FromJson, ToJson)

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Entry with FromJson::{from_json}

///|
pub extend Entry with ToJson::{to_json}

///|
pub fn EntryKind::is_dir(self : EntryKind) -> Bool {
  match self {
    Directory => true
    SymbolicLink(_, target_kind) => target_kind.is_dir()
    _ => false
  }
}

///|
/// Whether this entry is known to be a directory. False also covers failed lookups.
pub fn Entry::is_dir(self : Entry) -> Bool {
  self.kind is Ok(kind) && kind.is_dir()
}

///|
/// Whether this entry is known to be a link.
pub fn Entry::is_link(self : Entry) -> Bool {
  self.kind is Ok(kind) && kind.is_link()
}

///|
/// Whether this entry is a link, including links whose target is unavailable.
pub fn EntryKind::is_link(self : EntryKind) -> Bool {
  self is (SymbolicLink(_, _) | UnresolvedLink(_))
}
