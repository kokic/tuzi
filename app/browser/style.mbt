///|
let typography_style : Array[String] = [
  "--tuzi-entry-line-height: 1.25",
  @presentation.UI_FONT_STYLE,
]

///|
let appearance_style : Array[String] = [
  "--rui-item-group-gap: 8px", "--tuzi-row-height: 35px",
]

///|
let popover_style : Array[String] = [
  @presentation.UI_FONT_STYLE,
  "box-shadow: none",
  "border-color: var(--rui-border)",
]

///|
let dialog_footer_style : Array[String] = [
  "background: transparent", "border-radius: 0",
]

///|
fn application_style() -> Array[String] {
  [
    "display: flex", "flex-direction: column", "flex: 1", "min-height: 0", "min-width: 0",
    "padding: 8px",
  ]
}

///|
fn toolbar_style() -> Array[String] {
  [
    "flex: none", "display: grid", "grid-template-columns: minmax(0, 1fr) 1px minmax(0, 1fr)",
    "align-items: center", "min-height: 32px",
  ]
}

///|
fn count_style(active : Bool) -> Array[String] {
  if active {
    [
      "font-weight: var(--tuzi-weight-emphasis)", "color: var(--tuzi-emphasis-foreground)", "font-variant-numeric: tabular-nums",
    ]
  } else {
    [
      "font-weight: var(--tuzi-weight-ui)", "color: var(--rui-muted-foreground)", "font-variant-numeric: tabular-nums",
    ]
  }
}

///|
fn status_style() -> Array[String] {
  [
    "flex: 1", "min-width: 0", "min-height: 32px", "display: flex",
    "align-items: center", "gap: 8px", "overflow: hidden", "color: var(--rui-muted-foreground)",
  ]
}

///|
fn status_text_style() -> Array[String] {
  [
    "min-width: 0", "white-space: nowrap", "overflow: hidden", "text-overflow: ellipsis",
  ]
}
