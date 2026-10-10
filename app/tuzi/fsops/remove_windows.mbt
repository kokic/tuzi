///|
/// Git objects can be read-only; clear that bit before deleting them.
/// Elsewhere, clear it only after access denied. Attribute changes are not
/// rolled back if deletion fails.
#cfg(platform="windows")
async fn remove_path(path : Path) -> Unit {
  remove_tree_windows(path, inside_git_dir=has_git_dir_ancestor(path))
}

///|
/// Check lexical ancestors for a `.git` directory name, excluding `path` itself.
#cfg(platform="windows")
fn has_git_dir_ancestor(path : Path) -> Bool {
  for ancestor = path.dirname() {
    if ancestor.basename().to_lower() == ".git" {
      break true
    }
    let parent = ancestor.dirname()
    guard parent != ancestor else { break false }
    continue parent
  }
}

///|
/// Carry the Git policy through recursion without traversing links or junctions.
#cfg(platform="windows")
async fn remove_tree_windows(path : Path, inside_git_dir~ : Bool) -> Unit {
  let path_string = path.to_native()
  guard @async_fs.kind(path_string, follow_symlink=false) is Directory else {
    remove_file_windows(
      path_string,
      clear_readonly_before_delete=inside_git_dir,
    )
    return
  }
  let children_inside_git_dir = inside_git_dir ||
    path.basename().to_lower() == ".git"
  {
    let directory = @async_fs.opendir(path_string)
    defer directory.close()
    while directory.next(include_hidden=true, include_special=false)
          is Some(entry) {
      let child_path = path.join(Path("./\{entry.name}"))
      if entry.is_dir {
        remove_tree_windows(child_path, inside_git_dir=children_inside_git_dir)
      } else {
        remove_file_windows(
          child_path.to_native(),
          clear_readonly_before_delete=children_inside_git_dir,
        )
      }
    }
  }
  @async_fs.rmdir(path_string)
}

///|
#cfg(platform="windows")
async fn remove_file_windows(
  path : String,
  clear_readonly_before_delete~ : Bool,
) -> Unit {
  if clear_readonly_before_delete {
    ignore(clear_file_readonly_attribute(path))
    @async_fs.remove(path)
    return
  }
  @async_fs.remove(path) catch {
    @os_error.OSError(_) as error if error.is_EACCES() => {
      guard clear_file_readonly_attribute(path) else { raise error }
      @async_fs.remove(path)
    }
    error => raise error
  }
}

///|
/// Returns 1 if the read-only bit was cleared, 0 if unchanged, or a negated
/// Win32 error code on failure.
#cfg(platform="windows")
#borrow(path)
extern "C" fn clear_file_readonly_attribute_raw(path : String) -> Int = "tuzi_clear_readonly"

///|
/// Returns whether the bit changed; propagates the original Win32 error code.
#cfg(platform="windows")
fn clear_file_readonly_attribute(path : String) -> Bool raise {
  let status = clear_file_readonly_attribute_raw(path)
  guard status >= 0 else {
    raise @os_error.OSError(-status, context="clear read-only: \{path}")
  }
  status == 1
}
