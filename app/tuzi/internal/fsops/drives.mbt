///|
pub const SupportsDriveSelection : Bool = true

///|
#cfg(platform="windows")
extern "C" fn logical_drives_raw() -> Int = "tuzi_logical_drives"

///|
#cfg(platform="windows")
pub fn list_drives() -> Array[Path] raise {
  let mask = logical_drives_raw()
  guard mask >= 0 else { raise @os_error.OSError(-mask, context="list drives") }
  let drives = []
  for index = 0; index < 26; index = index + 1 {
    guard (mask & (1 << index)) != 0 else { continue }
    let letter = (65 + index).to_char().unwrap()
    drives.push(Path("\{letter}:/"))
  }
  drives
}

///|
#cfg(not(platform="windows"))
#borrow(error)
extern "C" fn mount_points_raw(error : FixedArray[Int]) -> FixedArray[Bytes] = "tuzi_mount_points"

///|
#cfg(not(platform="windows"))
pub async fn list_drives() -> Array[Path] {
  match @async.platform {
    MacOS => {
      let error = FixedArray::make(1, 0)
      let data = mount_points_raw(error)
      guard error[0] == 0 else {
        raise @os_error.OSError(error[0], context="list storage locations")
      }
      let paths = data
        .iter()
        .filter_map(bytes => decode_mount_path(bytes[:]))
        .to_array()
      storage_locations(paths)
    }
    Linux => {
      let data = @async_fs.read_file("/proc/self/mountinfo").binary()
      storage_locations(parse_mountinfo(data[:]))
    }
    Windows => panic()
  }
}
