///|
pub fn font_content_type(name : String) -> String? {
  match file_type_suffix(name) {
    ".ttf" => Some("font/ttf")
    ".otf" => Some("font/otf")
    ".woff" => Some("font/woff")
    ".woff2" => Some("font/woff2")
    _ => None
  }
}
