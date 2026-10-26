///|
#cfg(not(platform="windows"))
fn decode_mount_path(data : BytesView) -> String? {
  Some(@utf8.decode(data)) catch {
    @utf8.Malformed(_) => None
  }
}

///|
#cfg(not(platform="windows"))
fn split_mount_fields(data : BytesView, separator : Byte) -> Array[BytesView] {
  let parts = []
  let mut start = 0
  for index = 0; index < data.length(); index = index + 1 {
    if data[index] == separator {
      parts.push(data[start:index])
      start = index + 1
    }
  }
  parts.push(data[start:])
  parts
}

///|
#cfg(not(platform="windows"))
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
#cfg(not(platform="windows"))
fn is_system_filesystem(filesystem : String) -> Bool {
  filesystem
  is ("proc"
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
  | "bpf")
}

///|
#cfg(not(platform="windows"))
fn storage_locations(paths : Array[String]) -> Array[Path] {
  let unique = Set(paths[:])
  unique.add("/")
  let locations = unique.to_array()
  locations.sort()
  locations.map(path => Path(path))
}
