///|
/// Stream the original image so the browser retains animation and transparency.
async fn serve_image(
  req : @moonback.Request,
  res : @moonback.Responder,
) -> Unit {
  guard req.query().get("path") is Some(path) && !path.is_empty() else {
    res.send_text("Image path is required", status=400)
    return
  }
  let path = Path(path)
  let name = path.basename()
  guard @shared.image_content_type(name) is Some(_) else {
    res.send_text("Unsupported image format", status=415)
    return
  }
  stream_file(path, res)
}
