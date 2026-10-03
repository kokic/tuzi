///|
const SupportsDriveSelection : Bool = true

///|
#cfg(platform="windows")
extern "C" fn logical_drives_raw() -> Int = "tuzi_logical_drives"

///|
#cfg(platform="windows")
fn list_drives() -> Array[Path] raise {
  let mask = logical_drives_raw()
  guard mask >= 0 else { raise @os_error.OSError(-mask, context="list drives") }
  let drives = []
  for index in 0..<26 {
    if (mask & (1 << index)) != 0 {
      let letter = (65 + index).to_char().unwrap()
      drives.push(Path("\{letter}:/"))
    }
  }
  drives
}

///|
#cfg(platform="macos")
#borrow(error)
extern "C" fn mount_points_raw(error : FixedArray[Int]) -> FixedArray[Bytes] = "tuzi_mount_points"

///|
#cfg(platform="macos")
fn list_drives() -> Array[Path] raise {
  let error = FixedArray::make(1, 0)
  let data = mount_points_raw(error)
  guard error[0] == 0 else {
    raise @os_error.OSError(error[0], context="list storage locations")
  }
  let paths = []
  for bytes in data {
    if decode_mount_path(bytes[:]) is Some(path) {
      paths.push(path)
    }
  }
  storage_locations(paths)
}

///|
#cfg(platform="linux")
async fn list_drives() -> Array[Path] {
  let data = @async_fs.read_file("/proc/self/mountinfo").to_bytes()
  storage_locations(parse_mountinfo(data[:]))
}

///|
/// Only a path that cannot be represented by the application's String API is
/// skipped. Decoding the whole mount table would discard unrelated locations.
#cfg(not(platform="windows"))
fn decode_mount_path(data : BytesView) -> String? {
  Some(@utf8.decode(data)) catch {
    _ => None
  }
}

///|
#cfg(platform="linux")
fn split_mount_fields(data : BytesView, separator : Byte) -> Array[BytesView] {
  let parts = []
  let mut start = 0
  for index in 0..<data.length() {
    if data[index] == separator {
      parts.push(data[start:index])
      start = index + 1
    }
  }
  parts.push(data[start:])
  parts
}

///|
/// mountinfo escapes space, tab, newline and backslash as octal sequences.
/// Decode backslash last so a literal "\\040" does not become a space.
#cfg(platform="linux")
fn parse_mountinfo(data : BytesView) -> Array[String] {
  let paths = []
  for line in split_mount_fields(data, b'\n') {
    let fields = split_mount_fields(line, b' ')
    guard fields.get(4) is Some(field) &&
      fields.search_by(field => field.equal_to_bytes(b"-")) is Some(separator) &&
      fields.get(separator + 1) is Some(filesystem) else {
      continue
    }
    guard decode_mount_path(filesystem) is Some(filesystem) &&
      !is_system_filesystem(filesystem) &&
      decode_mount_path(field) is Some(path) else {
      continue
    }
    paths.push(
      path
      .replace_all(old="\\040", new=" ")
      .replace_all(old="\\011", new="\t")
      .replace_all(old="\\012", new="\n")
      .replace_all(old="\\134", new="\\"),
    )
  }
  paths
}

///|
/// These expose kernel interfaces, not file storage. In particular, tmpfs,
/// overlay and FUSE mounts remain eligible, wherever the user mounted them.
#cfg(platform="linux")
fn is_system_filesystem(filesystem : String) -> Bool {
  match filesystem {
    "proc"
    | "sysfs"
    | "devtmpfs"
    | "devpts"
    | "cgroup"
    | "cgroup2"
    | "securityfs"
    | "debugfs"
    | "tracefs"
    | "configfs"
    | "pstore"
    | "efivarfs"
    | "mqueue"
    | "hugetlbfs"
    | "fusectl"
    | "autofs"
    | "binfmt_misc"
    | "rpc_pipefs"
    | "nsfs"
    | "bpf" => true
    _ => false
  }
}

///|
/// Use only the mount table: metadata queries can block on disconnected mounts.
/// Linux file bind mounts remain listed because the table cannot distinguish them.
#cfg(not(platform="windows"))
fn storage_locations(paths : Array[String]) -> Array[Path] {
  let unique = Set(paths[:])
  unique.add("/")
  let locations = unique.to_array()
  // All mount points are absolute, so "/" sorts first.
  locations.sort()
  locations.map(path => Path(path))
}
