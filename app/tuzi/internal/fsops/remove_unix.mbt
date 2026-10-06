///|
#cfg(not(platform="windows"))
async fn remove_path(full : Path) -> Unit {
  let kind = @async_fs.kind(full.to_string(), follow_symlink=false)
  match kind {
    Directory => @async_fs.rmdir(full.to_string(), recursive=true)
    _ => @async_fs.remove(full.to_string())
  }
}
