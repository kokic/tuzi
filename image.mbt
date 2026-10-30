///|
pub fn image_content_type(name : String) -> String? {
  match file_type_suffix(name) {
    ".jpg" | ".jpeg" | ".jpe" | ".jfif" | ".pjpeg" | ".pjp" =>
      Some("image/jpeg")
    ".png" => Some("image/png")
    ".apng" => Some("image/apng")
    ".gif" => Some("image/gif")
    ".webp" => Some("image/webp")
    ".avif" => Some("image/avif")
    ".bmp" => Some("image/bmp")
    ".ico" | ".cur" => Some("image/x-icon")
    ".svg" | ".svgz" => Some("image/svg+xml")
    ".tif" | ".tiff" => Some("image/tiff")
    ".heic" => Some("image/heic")
    ".heif" => Some("image/heif")
    ".jxl" => Some("image/jxl")
    _ => None
  }
}
