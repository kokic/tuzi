///|
using @tuzi {type Entry, type EntryAppearance}

///|
pub(all) enum SortMode {
  Name
  Size
  Time
} derive(Eq)

///|
pub extend SortMode with Eq::{equal, not_equal}

///|
pub fn SortMode::next(self : SortMode) -> SortMode {
  match self {
    Name => Size
    Size => Time
    Time => Name
  }
}

///|
/// Folders first; names ascending, sizes descending, newest timestamps first.
pub fn SortMode::compare_entries(
  sort : SortMode,
  left : Entry,
  right : Entry,
) -> Int {
  guard left.is_dir() == right.is_dir() else {
    guard left.is_dir() else { return 1 }
    return -1
  }
  match sort {
    Name => left.name.lexical_compare(right.name)
    // Missing metadata follows known values in descending order.
    Size => right.size.unwrap_or(None).compare(left.size.unwrap_or(None))
    Time => right.mtime.to_option().compare(left.mtime.to_option())
  }
}
