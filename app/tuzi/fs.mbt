///|
using @shared {type Entry, preview_content_type}

///|
using @uniform_path {type Path}

///|
/// Filesystem APIs return host syntax; the protocol uses uniform syntax.
fn Path::from_native(input : String) -> Path {
  if @path.sep == '\\' {
    Path::from_windows(input)
  } else {
    Path(input)
  }
}

///|
/// The async runtime reports Windows FILETIME seconds (since 1601-01-01) on
/// Windows, and Unix epoch seconds elsewhere. Normalize to Unix epoch so the
/// browser formats every host's timestamps identically.
#cfg(platform="windows")
fn to_unix_seconds(sec : Int64) -> Int64 {
  sec - 11644473600L
}

///|
#cfg(not(platform="windows"))
fn to_unix_seconds(sec : Int64) -> Int64 {
  sec
}

///|
async fn list_entries(path : Path, include_markers~ : Bool) -> Array[Entry] {
  let path = Path::from_native(@async_fs.realpath(path.to_string()))
  let dir = @async_fs.opendir(path.to_string())
  defer dir.close()
  let jobs : Array[async () -> Entry?] = []
  while dir.next(include_hidden=true, include_special=false) is Some(entry) {
    jobs.push(() => {
      let full = path.join(Path("./\{entry.name}"))
      let full_path = full.to_string()
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
      let mtime = Ok(to_unix_seconds(@async_fs.mtime(full_path).0)) catch {
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
  match @async_fs.kind(path.to_string(), follow_symlink=false) {
    Regular => Regular
    Directory => Directory
    SymLink =>
      try {
        let target = Path::from_native(@async_fs.realpath(path.to_string()))
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
    guard !@async_fs.exists(path.join(Path("./\{marker}")).to_string()) else {
      return marker
    }
  }
  ""
}

///|
#cfg(not(platform="windows"))
async fn remove_path(full : Path) -> Unit {
  let kind = @async_fs.kind(full.to_string(), follow_symlink=false)
  match kind {
    Directory => @async_fs.rmdir(full.to_string(), recursive=true)
    _ => @async_fs.remove(full.to_string())
  }
}
