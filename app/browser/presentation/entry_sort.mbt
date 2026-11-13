///|
using @tuzi {type Entry, type EntryAppearance}

///|
#derive(Eq)
pub(all) enum SortMode {
  NameAscending
  NameDescending
  SizeDescending
  SizeAscending
  TimeDescending
  TimeAscending
}

///|
pub extend SortMode with Eq::{equal, not_equal}

///|
pub fn SortMode::next(self : SortMode) -> SortMode {
  match self {
    NameAscending => NameDescending
    NameDescending => SizeDescending
    SizeDescending => SizeAscending
    SizeAscending => TimeDescending
    TimeDescending => TimeAscending
    TimeAscending => NameAscending
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
    SizeDescending => right.size.unwrap_or(None).compare(left.size.unwrap_or(None))
    SizeAscending => left.size.unwrap_or(None).compare(right.size.unwrap_or(None))
    TimeDescending => right.mtime.to_option().compare(left.mtime.to_option())
    TimeAscending => left.mtime.to_option().compare(right.mtime.to_option())
  }
}
