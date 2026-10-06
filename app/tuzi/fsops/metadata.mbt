///|
/// The async runtime reports Windows FILETIME seconds (since 1601-01-01) on
/// Windows, and Unix epoch seconds elsewhere. Normalize to Unix epoch so the
/// browser formats every host's timestamps identically.
#cfg(platform="windows")
pub fn to_unix_seconds(sec : Int64) -> Int64 {
  sec - 11644473600L
}

///|
#cfg(not(platform="windows"))
pub fn to_unix_seconds(sec : Int64) -> Int64 {
  sec
}
