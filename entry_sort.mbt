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
/// Compare two entries using this mode; sizes and times sort ascending.
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
    Size => left.size.compare(right.size)
    Time => left.mtime.compare(right.mtime)
  }
}
