///|
pub(all) enum IconMode {
  None
  Svg
} derive(Debug, Eq, ToJson, FromJson)

///|
pub extend IconMode with Debug::{to_repr}

///|
pub extend IconMode with Eq::{not_equal, equal}

///|
pub fn IconMode::default_mode() -> IconMode {
  Svg
}

///|
/// Unknown values use the same fallback as an omitted startup option.
pub fn IconMode::parse(value : String) -> IconMode {
  match value {
    "none" => None
    "svg" => Svg
    _ => IconMode::default_mode()
  }
}

///|
pub fn IconMode::to_string(self : IconMode) -> String {
  match self {
    None => "none"
    Svg => "svg"
  }
}

///|
pub extend IconMode with ToJson::{to_json}

///|
pub extend IconMode with FromJson::{from_json}

///|
pub(all) enum IconTheme {
  None
  Svg(IconRegistry)
}

///|
pub fn icons_for(mode : IconMode) -> IconTheme {
  match mode {
    None => None
    Svg => Svg(builtin_svg_icons)
  }
}
