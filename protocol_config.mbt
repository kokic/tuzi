///|
pub(all) enum StartupMode {
  OpenDirectory
  RestoreHistory
} derive(ToJson, FromJson)

///|
pub(all) struct ServerConfig {
  base : Path
  startup : StartupMode
  theme : Theme
  icons : IconMode
  openers : OpenRegistry
  supports_drive_selection : Bool
} derive(ToJson, FromJson)

///|
pub(all) struct DirectoryRequest {
  path : Path
} derive(ToJson, FromJson)

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
pub(all) struct ListingRequest {
  path : Path
  include_markers : Bool
} derive(ToJson, FromJson)

///|
pub extend ListingRequest with ToJson::{to_json}

///|
pub extend ListingRequest with FromJson::{from_json}
