///|
pub async fn copy_entry(from : Path, to : Path) -> Unit {
  validate_transfer(from, to)
  copy_tree(from, to)
}

///|
/// Only regular files and directories are copied; links are never dereferenced.
/// Exclusive creation means cleanup only removes output owned by this operation.
async fn copy_tree(from : Path, to : Path) -> Unit {
  let kind = @async_fs.kind(from.to_string(), follow_symlink=false)
  match kind {
    Directory => {
      @async_fs.mkdir(to.to_string())
      errdefer cleanup_copy(to)
      let dir = @async_fs.opendir(from.to_string())
      defer dir.close()
      while dir.next(include_hidden=true, include_special=false) is Some(entry) {
        let child = Path("./\{entry.name}")
        copy_tree(from.join(child), to.join(child))
      }
    }
    Regular => copy_file(from, to)
    _ => raise FileError::UnsupportedEntry(from.to_string())
  }
}

///|
pub async fn cleanup_copy(path : Path) -> Unit nocancel {
  @async.protect_from_cancel(() => {
    remove_path(path) catch {
      error => raise CleanupFailed(path, error)
    }
  })
}

///|
async fn copy_file(from : Path, to : Path) -> Unit {
  let src = @async_fs.open(from.to_string(), mode=ReadOnly)
  defer src.close()
  let dst = @async_fs.create(to.to_string(), allow_existing=false)
  defer dst.close()
  errdefer {
    dst.close()
    cleanup_copy(to)
  }
  while src.read_some(max_len=64 * 1024) is Some(data) {
    dst.write(data)
    @async.pause()
  }
}

///|
extern "C" fn is_cross_device_error(code : Int) -> Bool = "tuzi_is_cross_device_error"

///|
pub async fn move_entry(from : Path, to : Path) -> Unit {
  validate_transfer(from, to)
  rename_path(from, to) catch {
    @os_error.OSError(code, ..) as error => {
      guard is_cross_device_error(code) else { raise error }
      copy_tree(from, to)
      remove_path(from) catch {
        error => raise SourceRemovalFailed(from, to, error)
      }
    }
    error => raise error
  }
}
