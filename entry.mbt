///|
pub(all) struct Entry {
  name : String
  is_dir : Bool
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
