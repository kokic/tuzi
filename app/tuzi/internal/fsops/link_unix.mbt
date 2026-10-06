///|
#cfg(not(platform="windows"))
async fn read_link_text(path : Path) -> String {
  let output = link_command("readlink", [path.to_string()])
  // readlink adds one newline; retain any newline belonging to the target.
  output.view(end_offset=output.length() - 1).to_owned()
}

///|
#cfg(not(platform="windows"))
async fn create_link_like(
  _source : Path,
  destination : Path,
  target : Path,
) -> Unit {
  @async_fs.symlink(target=target.to_string(), destination.to_string())
}

///|
#cfg(not(platform="windows"))
async fn relocate_link(source : Path, destination : Path) -> Unit {
  @async_fs.rename(source.to_string(), destination.to_string(), replace=false)
}
