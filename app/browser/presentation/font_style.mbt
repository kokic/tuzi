///|
/// UI and prose use the active theme's UI family.
pub const UI_FONT_STYLE : String = "font-family: var(--tuzi-font-ui)"

///|
/// File names, filter input, text/code and shortcuts use the content family.
pub const CONTENT_FONT_STYLE : String = "font-family: var(--tuzi-font-content)"

///|
/// Font previews intentionally use the loaded font rather than a theme family.
pub fn preview_font_style(family : String) -> String {
  "font-family: '\{family}', '\{family}-notdef'"
}
