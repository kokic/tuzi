///|
/// Font formats supported by the browser preview.
pub fn font_content_type(name : String) -> String? {
  match @posix.Path(name.to_lower()).extname().to_owned() {
    ".ttf" => Some("font/ttf")
    ".otf" => Some("font/otf")
    ".woff" => Some("font/woff")
    ".woff2" => Some("font/woff2")
    _ => None
  }
}
