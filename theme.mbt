///|
pub(all) enum Theme {
  Light
  Dark
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Parse a `--theme` flag value; unknown values use the default theme.
pub fn Theme::parse(s : String) -> Theme {
  match s {
    "light" => Light
    "dark" => Dark
    _ => Theme::default()
  }
}

///|
pub fn Theme::to_string(self : Theme) -> String {
  match self {
    Light => "light"
    Dark => "dark"
  }
}

///|
pub extend Theme with ToJson::{to_json}

///|
pub extend Theme with FromJson::{from_json}

///|
pub extend Theme with Eq::{equal, not_equal}

///|
pub extend Theme with Debug::{to_repr}

///|
pub impl Default for Theme with fn default() -> Theme {
  Light
}

///|
pub extend Theme with Default::{default}
