///|
pub fn row_style(is_cursor : Bool) -> Array[String] {
  [
    UI_FONT_STYLE,
    "display: grid",
    "grid-column: 1 / -1",
    "grid-template-columns: subgrid",
    "align-items: center",
    "min-width: 0",
    "padding: 0",
    "cursor: pointer",
    "-webkit-user-select: none",
    "user-select: none",
    "line-height: var(--tuzi-entry-line-height)",
    "background: var(--tuzi-row-hover, transparent)",
    ..if is_cursor {
      ["--tuzi-entry-name-weight: var(--tuzi-weight-cursor)"]
    },
  ]
}

///|
pub fn entry_open_area_style() -> Array[String] {
  [
    "grid-column: 2 / -1", "display: grid", "grid-template-columns: subgrid", "align-items: baseline",
    "min-width: 0",
  ]
}

///|
pub fn entry_title_style(entry : Entry, color : String) -> Array[String] {
  let foreground = match color {
    "currentColor" if entry.name.has_prefix(".") =>
      "var(--rui-muted-foreground)"
    "currentColor" => "var(--rui-foreground)"
    _ =>
      "light-dark(oklch(from \{color} min(l, 0.5) c h / 1), oklch(from \{color} max(l, 0.75) c h / 1))"
  }
  [
    CONTENT_FONT_STYLE,
    "min-width: 0",
    "grid-column: 1",
    "display: flex",
    "align-items: baseline",
    "overflow: hidden",
    "white-space: nowrap",
    "font-size: var(--tuzi-content-size)",
    "font-weight: var(--tuzi-entry-name-weight, var(--tuzi-weight-ui))",
    "color: \{foreground}",
  ]
}

///|
/// Shared typography and color for entry numbers, sizes and timestamps.
pub fn entry_meta_style() -> Array[String] {
  [
    METADATA_FONT_STYLE,
    "min-width: 0",
    "overflow: hidden",
    "white-space: nowrap",
    "text-overflow: ellipsis",
    "font-size: var(--tuzi-secondary-size)",
    "font-variant-numeric: tabular-nums",
    "color: var(--tuzi-entry-secondary-foreground)",
  ]
}

///|
pub fn entry_details_style() -> Array[String] {
  [
    METADATA_FONT_STYLE,
    "flex: none",
    "display: flex",
    "align-items: center",
    "gap: 8px",
    "padding: 4px",
    "font-size: var(--tuzi-secondary-size)",
    "color: var(--rui-muted-foreground)",
    "min-width: 0",
    "line-height: 18px",
    "border-top: 1px solid var(--rui-border)",
    "background: var(--rui-background)",
  ]
}
