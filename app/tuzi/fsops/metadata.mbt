///|
#cfg(platform="windows")
pub fn to_unix_seconds(sec : Int64) -> Int64 {
  sec - 11644473600L
}

///|
#cfg(not(platform="windows"))
pub fn to_unix_seconds(sec : Int64) -> Int64 {
  sec
}
