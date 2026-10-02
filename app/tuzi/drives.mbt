///|
#cfg(platform="windows")
const SupportsDriveSelection : Bool = true

///|
#cfg(not(platform="windows"))
const SupportsDriveSelection : Bool = false

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
#cfg(not(platform="windows"))
fn list_drives() -> Array[Path] raise {
  []
}
