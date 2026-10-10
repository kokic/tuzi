///|
using @shared {type Entry}

///|
using @uniform_path {type Path}

///|
async fn list_entries(path : Path, include_markers~ : Bool) -> Array[Entry] {
  let path = @fsops.path_from_native(@async_fs.realpath(path.to_native()))
  let dir = @async_fs.opendir(path.to_native())
  defer dir.close()
  let jobs : Array[async () -> Entry?] = []
  while dir.next(include_hidden=true, include_special=false) is Some(entry) {
    jobs.push(() => {
      let full = path.join(Path("./\{entry.name}"))
      let full_path = full.to_native()
      let kind = read_entry_kind(full) catch {
        // The entry may disappear after directory enumeration.
        @os_error.OSError(_, ..) as error if error.is_ENOENT() => return None
        error => raise error
      }
      let is_dir = kind.is_dir()
      let size = {
        guard !is_dir else { Ok(None) }
        // Metadata calls never open FIFOs/devices as input streams.
        Ok(Some(@async_fs.file_size(full_path))) catch {
          error => Err(api_failure(error))
        }
      }
      let mtime = Ok(@fsops.to_unix_seconds(@async_fs.mtime(full_path).0)) catch {
        error => Err(api_failure(error))
      }
      let marker = {
        guard is_dir && include_markers else { Ok("") }
        Ok(detect_marker(full)) catch {
          error => Err(api_failure(error))
        }
      }
      Some({ name: entry.name, kind, size, mtime, marker, })
    })
  }
  @async.all(jobs[:], max_concurrent=8).filter_map(entry => entry)
}

///|
async fn read_entry_kind(path : Path) -> @shared.EntryKind {
  match @async_fs.kind(path.to_native(), follow_symlink=false) {
    Regular => Regular
    Directory => Directory
    SymLink =>
      try {
        let target = @fsops.path_from_native(
          @async_fs.realpath(path.to_native()),
        )
        SymbolicLink(target, read_entry_kind(target))
      } catch {
        @os_error.OSError(_, ..) as error => UnresolvedLink(api_failure(error))
        error => raise error
      }
    Socket => Socket
    Pipe => Pipe
    BlockDevice => BlockDevice
    CharDevice => CharDevice
    Unknown => Unknown
  }
}

///|
async fn detect_marker(path : Path) -> String {
  for marker in @shared.folder_markers {
    guard !@async_fs.exists(path.join(Path("./\{marker}")).to_native()) else {
      return marker
    }
  }
  ""
}
