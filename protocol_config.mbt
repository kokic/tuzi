///|
#derive(ToJson, FromJson)
pub(all) enum StartupMode {
  OpenDirectory
  RestoreHistory
}

///|
#derive(ToJson, FromJson)
pub(all) struct ServerConfig {
  base : Path
  startup : StartupMode
  theme : Theme
  entry_appearance : EntryAppearance
  openers : OpenRegistry
  supports_drive_selection : Bool
}

///|
#derive(ToJson, FromJson)
pub(all) struct DirectoryRequest {
  path : Path
}

///|
pub extend StartupMode with ToJson::{to_json}

///|
pub extend StartupMode with FromJson::{from_json}

///|
pub extend ServerConfig with ToJson::{to_json}

///|
pub extend ServerConfig with FromJson::{from_json}

///|
pub extend DirectoryRequest with ToJson::{to_json}

///|
pub extend DirectoryRequest with FromJson::{from_json}

///|
#derive(ToJson, FromJson)
pub(all) struct ListingRequest {
  path : Path
  include_markers : Bool
}

///|
pub extend ListingRequest with ToJson::{to_json}

///|
pub extend ListingRequest with FromJson::{from_json}

///|
#derive(ToJson, FromJson)
pub(all) struct DirectoryCountsRequest {
  path : Path
  names : Array[String]
}

///|
pub extend DirectoryCountsRequest with ToJson::{to_json}

///|
pub extend DirectoryCountsRequest with FromJson::{from_json}
