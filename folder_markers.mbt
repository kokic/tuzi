///|
pub(all) enum FolderMarkerKind {
  MoonBit
  Rust
  Node
  Git
}

///|
pub let folder_marker_kinds : Map[String, FolderMarkerKind] = {
  "moon.mod": MoonBit,
  "moon.work": MoonBit,
  "Cargo.toml": Rust,
  "package.json": Node,
  ".git": Git,
}

///|
pub let folder_markers : Array[String] = folder_marker_kinds.keys().to_array()
