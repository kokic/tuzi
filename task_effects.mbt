///|
/// Directories whose immediate entries may change, including partial failure.
/// Callers must account separately for metadata in parent listings and for
/// subtrees created, removed, moved, or changed by a Git checkout.
pub fn TaskKind::affected_directories(self : TaskKind) -> Array[Path] {
  match self {
    File(Delete(target~)) => [target.dirname()]
    File(Rename(source~, ..)) => [source.dirname()]
    File(CreateFile(parent~, ..)) | File(Mkdir(parent~, ..)) => [parent]
    File(Zip(directory~, ..)) => [directory]
    File(Unzip(destination~, ..)) => [destination.dirname(), destination]
    File(Copy(destination~, ..)) => [destination.dirname()]
    File(Move(source~, destination~)) =>
      [source.dirname(), destination.dirname()]
    File(EditLink(source~, destination~, ..)) =>
      [source.dirname(), destination.dirname(), source, destination]
    Git(request) => [request.path.dirname()]
  }
}

///|
/// A listing contains direct children and their metadata. Changing a directory
/// also changes its entry in the parent listing (mtime and folder marker), but
/// does not invalidate unrelated descendants of either directory.
pub fn TaskKind::affects_listing(kind : TaskKind, directory : Path) -> Bool {
  if kind
    .affected_directories()
    .any(changed => directory == changed || directory == changed.dirname()) {
    return true
  }
  match kind {
    File(Delete(target~)) => directory_contains(target, directory)
    File(Rename(source~, new_name~)) =>
      directory_contains(source, directory) ||
      directory_contains(
        source.dirname().join(Path("./\{new_name}")),
        directory,
      )
    File(Copy(destination~, ..)) => directory_contains(destination, directory)
    File(Unzip(destination~, ..)) => directory_contains(destination, directory)
    File(Move(source~, destination~))
    | File(EditLink(source~, destination~, ..)) =>
      directory_contains(source, directory) ||
      directory_contains(destination, directory)
    File(Mkdir(parent~, name~)) => directory == parent.join(Path("./\{name}"))
    File(CreateFile(..)) | File(Zip(..)) => false
    Git(request) => {
      let subtree = match request.operation {
        Pull | Switch(_) => request.path.dirname()
        Push | DeleteBranch(_) | RenameBranch(_, _) | Prune => request.path
      }
      directory_contains(subtree, directory)
    }
  }
}

///|
pub fn directory_contains(directory : Path, path : Path) -> Bool {
  for current = path {
    if current == directory {
      break true
    }
    let parent = current.dirname()
    guard parent != current else { break false }
    continue parent
  }
}
