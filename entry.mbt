///|
pub(all) enum EntryKind {
  Regular
  Directory
  SymbolicLink(Path, EntryKind)
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
  kind : Result[EntryKind, ApiFailure]
  size : Result[Int64?, ApiFailure]
  mtime : Result[Int64, ApiFailure]
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
pub fn Entry::is_dir(self : Entry) -> Bool {
  self.kind is Ok(kind) && kind.is_dir()
}

///|
pub fn Entry::is_link(self : Entry) -> Bool {
  self.kind is Ok(kind) && kind.is_link()
}

///|
pub fn EntryKind::is_link(self : EntryKind) -> Bool {
  self is (SymbolicLink(_, _) | UnresolvedLink(_))
}
