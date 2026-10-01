///|
/// MIME types for image formats a browser may decode. Support for formats such
/// as TIFF, HEIC and JPEG XL depends on the browser; decoding stays native.
pub fn image_content_type(name : String) -> String? {
  match @posix.Path(name.to_lower()).extname().to_owned() {
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
