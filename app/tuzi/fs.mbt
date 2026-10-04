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
  let jobs : Array[async () -> Entry] = []
  while dir.next(include_hidden=true, include_special=false) is Some(entry) {
    jobs.push(() => {
      let full = path.join(Path("./\{entry.name}"))
      let full_path = full.to_string()
      let kind = read_entry_kind(full)
      let is_dir = kind.is_dir()
      let size = if is_dir {
        None
      } else {
        // Metadata calls never open FIFOs/devices as input streams.
        Some(@async_fs.file_size(full_path)) catch {
          _ => None
        }
      }
      let mtime = Some(to_unix_seconds(@async_fs.mtime(full_path).0)) catch {
        _ => None
      }
      let marker = if is_dir && include_markers {
        detect_marker(full)
      } else {
        ""
      }
      { name: entry.name, kind, size, mtime, marker, }
    })
  }
  @async.all(jobs[:], max_concurrent=8)
}

///|
async fn read_entry_kind(path : Path) -> @shared.EntryKind {
  match @async_fs.kind(path.to_string(), follow_symlink=false) {
    Regular => Regular
    Directory => Directory
    SymLink => {
      let target = Path::from_native(@async_fs.realpath(path.to_string()))
      SymbolicLink(target, read_entry_kind(target))
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
    let found = @async_fs.exists(path.join(Path("./\{marker}")).to_string()) catch {
      _ => false
    }
    if found {
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
