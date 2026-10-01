///|
async fn serve_file(req : @moonback.Request, res : @moonback.Responder) -> Unit {
  guard req.query().get("path") is Some(path) && !path.is_empty() else {
    res.send_text("File path is required", status=400)
    return
  }
  let path = Path(path)
  stream_file(path, res)
}

///|
async fn stream_file(path : Path, res : @moonback.Responder) -> Unit {
  let file = try {
    guard @async_fs.kind(path.to_string()) is Regular else {
      res.send_text("Not a regular file", status=415)
      return
    }
    @async_fs.open(path.to_string(), mode=ReadOnly)
  } catch {
    error => {
      let failure = api_failure(error)
      let status = match failure.code {
        NotFound => 404
        PermissionDenied => 403
        _ => 500
      }
      res.send_text(failure.message, status~)
      return
    }
  }
  defer file.close()
  let size = file.size()
  guard preview_content_type(path, size) is Some(content_type) else {
    res.send_text(
      "Unsupported file format: unknown files must be at most 1 MiB",
      status=415,
    )
    return
  }
  let headers : Array[(String, String)] = [
    ("Content-Type", content_type),
    ("Content-Length", size.to_string()),
    ("Cache-Control", "no-store"),
    ("X-Content-Type-Options", "nosniff"),
    // Active documents must not execute scripts against the file browser.
    ..if content_type.has_prefix("text/html") ||
      content_type == "image/svg+xml" ||
      content_type.has_prefix("application/xml") {
      [
        (
          "Content-Security-Policy", "sandbox allow-downloads; default-src 'none'; style-src 'unsafe-inline'",
        ),
      ]
    },
    ..if path.basename().to_lower().has_suffix(".svgz") {
      [("Content-Encoding", "gzip")]
    },
  ]
  let writer = res.respond(headers~)
  writer.write_reader(file)
}
