///|
pub(all) enum EntryAppearance {
  Plain
  Decorated
} derive(Debug, Eq, ToJson, FromJson)

///|
pub extend EntryAppearance with Debug::{to_repr}

///|
pub extend EntryAppearance with Eq::{not_equal, equal}

///|
pub impl Default for EntryAppearance with fn default() -> EntryAppearance {
  Decorated
}

///|
pub extend EntryAppearance with Default::{default}

///|
/// Unknown values use the same fallback as an omitted startup option.
pub fn EntryAppearance::parse(value : String) -> EntryAppearance {
  match value {
    "plain" => Plain
    "decorated" => Decorated
    _ => EntryAppearance::default()
  }
}

///|
pub fn EntryAppearance::to_string(self : EntryAppearance) -> String {
  match self {
    Plain => "plain"
    Decorated => "decorated"
  }
}

///|
pub extend EntryAppearance with ToJson::{to_json}

///|
pub extend EntryAppearance with FromJson::{from_json}
