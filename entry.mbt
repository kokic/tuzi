///|
pub(all) enum EntryKind {
  Regular
  Directory
  /// A symbolic link or Windows junction, carrying its final absolute target.
  SymbolicLink(Path, EntryKind)
  /// The link exists, but its target could not be resolved or inspected.
  UnresolvedLink(String)
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
  kind : EntryKind
  /// File size in bytes; absent for directories or unavailable metadata.
  size : Int64?
  /// Modification time in Unix seconds; absent when metadata is unavailable.
  mtime : Int64?
  /// The first name in `folder_markers` found directly inside this directory,
  /// or "" when none. Always "" for files.
  marker : String
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
pub fn Entry::is_dir(self : Entry) -> Bool {
  self.kind.is_dir()
}

///|
/// Whether this entry is a link, including links whose target is unavailable.
pub fn EntryKind::is_link(self : EntryKind) -> Bool {
  self is (SymbolicLink(_, _) | UnresolvedLink(_))
}
