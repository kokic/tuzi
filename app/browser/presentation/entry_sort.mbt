///|
using @tuzi {type Entry, type EntryAppearance}

///|
#derive(Eq)
pub(all) enum SortMode {
  NameAscending
  NameDescending
  Size
  Time
}

///|
pub extend SortMode with Eq::{equal, not_equal}

///|
pub fn SortMode::next(self : SortMode) -> SortMode {
  match self {
    NameAscending => NameDescending
    NameDescending => Size
    Size => Time
    Time => NameAscending
  }
}

///|
pub fn SortMode::compare_entries(
  sort : SortMode,
  left : Entry,
  right : Entry,
) -> Int32 {
  guard left.is_dir() == right.is_dir() else {
    guard left.is_dir() else { return 1 }
    return -1
  }
  match sort {
    NameAscending => left.name.lexical_compare(right.name)
    NameDescending => right.name.lexical_compare(left.name)
    Size => right.size.unwrap_or(None).compare(left.size.unwrap_or(None))
    Time => right.mtime.to_option().compare(left.mtime.to_option())
  }
}
