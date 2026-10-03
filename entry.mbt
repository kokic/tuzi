///|
pub(all) struct Entry {
  name : String
  /// Whether the entry resolves to a directory, including directory links.
  is_dir : Bool
  /// The entry itself is a symbolic link (or a Windows junction).
  is_symlink : Bool
  /// Final absolute target of a link; absent for non-links or failed resolution.
  resolved_target : Path?
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
