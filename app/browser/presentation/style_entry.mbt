///|
/// Resolve the filename foreground, including hidden entries and theme adaptation.
pub fn entry_foreground(entry : Entry, color : String) -> String {
  match color {
    "currentColor" if entry.name.has_prefix(".") =>
      "var(--rui-muted-foreground)"
    "currentColor" => "var(--rui-foreground)"
    _ => entry_theme_color(color)
  }
}

///|
pub fn entry_title_style(entry : Entry, color : String) -> Array[String] {
  ["color: \{entry_foreground(entry, color)}"]
}

///|
fn entry_theme_color(color : String) -> String {
  "light-dark(oklch(from \{color} min(l, 0.5) c h / 1), oklch(from \{color} max(l, 0.75) c h / 1))"
}

///|
/// The ordinary directory color, adapted to the active color scheme.
pub fn directory_foreground() -> String {
  entry_theme_color(builtin_entry_colors.folder)
}
