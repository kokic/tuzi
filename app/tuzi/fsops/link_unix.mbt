///|
#cfg(not(platform="windows"))
async fn read_link_text(path : Path) -> String {
  let output = link_command("readlink", [path.to_string()])
  output.view(end_offset=output.length() - 1).to_owned()
}

///|
#cfg(not(platform="windows"))
async fn create_link_like(
  _source : Path,
  destination : Path,
  target : Path,
) -> Unit {
  create_link(target, destination)
}

///|
/// Create a symbolic link without replacing an existing destination.
#cfg(not(platform="windows"))
pub async fn create_link(target : Path, destination : Path) -> Unit {
  @async_fs.symlink(target=target.to_native(), destination.to_native())
}

///|
#cfg(not(platform="windows"))
async fn relocate_link(source : Path, destination : Path) -> Unit {
  @async_fs.rename(source.to_string(), destination.to_string(), replace=false)
}
