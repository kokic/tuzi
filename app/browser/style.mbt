///|
let appearance_style : Array[String] = [
  "--rui-radius: 6px", "--tuzi-selection-background: light-dark(#e5e5e5, #3a3a3a)",
  "--tuzi-selection-indicator: var(--rui-muted-foreground)", "--tuzi-marked-background: light-dark(#f0f0f0, #303030)",
  "--tuzi-row-height: 35px",
]

///|
fn application_style() -> Array[String] {
  [
    "display: flex", "flex-direction: column", "flex: 1", "min-height: 0", "min-width: 0",
    "padding: 8px", "gap: 6px",
  ]
}

///|
fn toolbar_style() -> Array[String] {
  [
    "flex: none", "display: flex", "flex-wrap: wrap", "align-items: center", "gap: 8px",
    "padding: 0 2px", "min-height: 32px",
  ]
}

///|
fn count_style(active : Bool) -> Array[String] {
  if active {
    [
      "font-weight: 600", "color: var(--rui-primary)", "font-variant-numeric: tabular-nums",
    ]
  } else {
    [
      "font-weight: 500", "color: var(--rui-muted-foreground)", "font-variant-numeric: tabular-nums",
    ]
  }
}

///|
fn status_style() -> Array[String] {
  [
    "flex: 1 1 240px", "min-width: 0", "max-width: 100%", "min-height: 32px", "display: flex",
    "align-items: center", "gap: 8px", "overflow: hidden", "color: var(--rui-muted-foreground)",
  ]
}

///|
fn status_text_style() -> Array[String] {
  [
    "min-width: 0", "white-space: nowrap", "overflow: hidden", "text-overflow: ellipsis",
  ]
}
