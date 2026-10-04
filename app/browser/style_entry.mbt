///|
fn row_style(is_cursor : Bool, selected : Bool) -> Array[String] {
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
    "background: var(--tuzi-row-background, var(--tuzi-row-hover, transparent))",
    ..if is_cursor {
      [
        "--tuzi-row-background: var(--tuzi-cursor-background)", "box-shadow: inset 2px 0 var(--tuzi-cursor-indicator)",
      ]
    } else if selected {
      ["--tuzi-row-background: var(--tuzi-marked-background)"]
    } else {
      []
    },
  ]
}

///|
fn entry_open_area_style() -> Array[String] {
  [
    "grid-column: 3 / -1", "display: grid", "grid-template-columns: subgrid", "align-items: baseline",
    "min-width: 0",
  ]
}

///|
fn entry_title_style(entry : Entry, color : String) -> Array[String] {
  let foreground = match color {
    "currentColor" if entry.name.has_prefix(".") =>
      "var(--rui-muted-foreground)"
    "currentColor" => "var(--rui-foreground)"
    // Keep the matched hue, adjusting lightness for readable text in either theme.
    _ =>
      "light-dark(oklch(from \{color} min(l, 0.5) c h / 1), oklch(from \{color} max(l, 0.75) c h / 1))"
  }
  [
    CODE_FONT_STYLE,
    "min-width: 0",
    "grid-column: 1",
    "display: flex",
    "align-items: baseline",
    if entry.kind.is_link() {
      "overflow-x: auto"
    } else {
      "overflow: hidden"
    },
    "white-space: nowrap",
    "font-size: var(--tuzi-entry-title-size)",
    "color: \{foreground}",
  ]
}

///|
fn entry_meta_style() -> Array[String] {
  [
    CODE_FONT_STYLE,
    "min-width: 0",
    "overflow: hidden",
    "white-space: nowrap",
    "text-overflow: ellipsis",
    "font-size: var(--tuzi-entry-subtitle-size)",
    "color: var(--rui-muted-foreground)",
  ]
}

///|
fn entry_details_style() -> Array[String] {
  [
    CODE_FONT_STYLE,
    "flex: none",
    "display: flex",
    "align-items: center",
    "gap: 8px",
    "padding: 4px",
    "font-size: var(--tuzi-footer-size)",
    "color: var(--rui-muted-foreground)",
    "min-width: 0",
    "line-height: 18px",
    "border-top: 1px solid var(--rui-border)",
    "background: var(--rui-background)",
  ]
}
