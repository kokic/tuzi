///|
/// Resolve a browser preview type. Unknown formats up to 1 MiB are plain text;
/// larger unknown files cannot be opened.
pub fn preview_content_type(path : Path, size : Int64) -> String? {
  if path.content_type() is Some(content_type) {
    return Some(content_type)
  }
  guard size <= 1_048_576L else { return None }
  Some("text/plain; charset=utf-8")
}

///|
fn Path::content_type(path : Path) -> String? {
  let name = path.basename()
  if image_content_type(name) is Some(content_type) {
    return Some(content_type)
  }
  Some(
    match @posix.Path(name.to_lower()).extname().to_owned() {
      ".pdf" => "application/pdf"
      ".html" | ".htm" => "text/html; charset=utf-8"
      ".json" | ".map" => "application/json; charset=utf-8"
      ".xml" => "application/xml; charset=utf-8"
      ".txt"
      | ".md"
      | ".markdown"
      | ".csv"
      | ".tsv"
      | ".log"
      | ".toml"
      | ".yaml"
      | ".yml"
      | ".ini"
      | ".conf"
      | ".mbt"
      | ".mbti"
      | ".mod"
      | ".pkg"
      | ".js"
      | ".mjs"
      | ".ts"
      | ".css"
      | ".py"
      | ".rs"
      | ".c"
      | ".h"
      | ".cpp"
      | ".hpp"
      | ".go"
      | ".java"
      | ".sh" => "text/plain; charset=utf-8"
      ".mp4" | ".m4v" => "video/mp4"
      ".webm" => "video/webm"
      ".ogv" => "video/ogg"
      ".mov" => "video/quicktime"
      ".mp3" => "audio/mpeg"
      ".m4a" => "audio/mp4"
      ".aac" => "audio/aac"
      ".wav" => "audio/wav"
      ".ogg" | ".oga" | ".opus" => "audio/ogg"
      ".flac" => "audio/flac"
      _ => return None
    },
  )
}
