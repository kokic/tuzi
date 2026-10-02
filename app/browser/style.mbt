///|
let appearance_style : Array[String] = [
  "--rui-radius: 6px", "--rui-background: light-dark(#fafafa, #202020)", "--rui-card: light-dark(#ffffff, #262626)",
  "--rui-card-foreground: var(--rui-foreground)", "--rui-popover: var(--rui-card)",
  "--rui-popover-foreground: var(--rui-foreground)", "--rui-input-background: var(--rui-card)",
  "--rui-outline-background: var(--rui-card)", "--tuzi-header-background: light-dark(#fafafa, #242424)",
  "--tuzi-selection-background: light-dark(#e5e5e5, #3a3a3a)", "--tuzi-selection-indicator: var(--rui-muted-foreground)",
  "--tuzi-marked-background: light-dark(#f0f0f0, #303030)",
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
fn panes_style() -> Array[String] {
  [
    "flex: 1", "min-height: 0", "display: flex", "gap: 1px", "overflow: clip", "border: 1px solid var(--rui-border)",
    "border-radius: var(--rui-radius)", "background: var(--rui-border)",
  ]
}

///|
fn pane_style(active : Bool) -> Array[String] {
  [
    "flex: 1",
    "min-width: 0",
    "display: flex",
    "flex-direction: column",
    "min-height: 0",
    "box-sizing: border-box",
    "overflow: clip",
    "background: var(--rui-card)",
    ..if active {
      [
        "--tuzi-cursor-background: var(--tuzi-selection-background)", "--tuzi-cursor-indicator: var(--tuzi-selection-indicator)",
      ]
    } else {
      [
        "--tuzi-cursor-background: var(--rui-muted)", "--tuzi-cursor-indicator: var(--rui-border)",
      ]
    },
  ]
}

///|
fn pane_header_style(active : Bool) -> Array[String] {
  [
    "flex: none",
    "display: flex",
    "align-items: center",
    "gap: 8px",
    "font-size: var(--tuzi-pane-header-size)",
    "padding: 3px 8px",
    "min-height: 28px",
    "border-bottom: 1px solid var(--rui-border)",
    "background: var(--tuzi-header-background)",
    ..if active {
      ["background: var(--rui-muted)"]
    },
  ]
}

///|
fn pane_list_style() -> Array[String] {
  [
    "flex: 1", "display: grid", "grid-template-columns: max-content max-content max-content minmax(0, 1fr)",
    "column-gap: 8px", "align-content: start", "overflow-y: auto", "margin: 0", "padding: 4px 0",
    "list-style: none", "scrollbar-width: thin", "scrollbar-color: var(--rui-border) transparent",
  ]
}

///|
fn pane_status_style() -> Array[String] {
  ["padding: 20px 16px", "margin: 0", "font-size: 0.8125rem"]
}

///|
fn row_style(is_cursor : Bool, selected : Bool) -> Array[String] {
  [
    "display: grid",
    "grid-column: 1 / -1",
    "grid-template-columns: subgrid",
    "align-items: center",
    "min-width: 0",
    "padding: 4px 10px",
    "cursor: pointer",
    // Only the filename child opts back into text selection.
    "-webkit-user-select: none",
    "user-select: none",
    "line-height: var(--tuzi-entry-line-height)",
    "background: var(--tuzi-row-background, var(--tuzi-row-hover, transparent))",
    "transition: background-color 100ms ease",
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
    "grid-column: 3 / -1", "display: grid", "grid-template-columns: subgrid", "align-items: center",
    "align-self: stretch", "min-width: 0",
  ]
}

///|
fn entry_content_style() -> Array[String] {
  [
    "grid-column: 2", "display: flex", "flex-direction: column", "min-width: 0",
    "content-visibility: auto", "contain-intrinsic-block-size: auto var(--tuzi-entry-height)",
  ]
}

///|
fn icon_box_style() -> Array[String] {
  [
    "position: relative", "content-visibility: auto", "align-self: center", "width: var(--tuzi-entry-height)",
    "height: var(--tuzi-entry-height)", "display: inline-flex", "align-items: center",
    "justify-content: center", "overflow: hidden",
  ]
}

///|
fn entry_title_style(entry : Entry) -> Array[String] {
  [
    "overflow: hidden",
    "white-space: nowrap",
    "text-overflow: ellipsis",
    "font-size: var(--tuzi-entry-title-size)",
    ..if entry.name.has_prefix(".") {
      ["color: var(--rui-muted-foreground)"]
    },
  ]
}

///|
fn entry_meta_style() -> Array[String] {
  [
    "overflow: hidden", "white-space: nowrap", "text-overflow: ellipsis", "font-size: var(--tuzi-entry-subtitle-size)",
    "color: var(--rui-muted-foreground)",
  ]
}

///|
fn entry_details_style() -> Array[String] {
  [
    "flex: none", "padding: 4px 10px", "font-size: var(--tuzi-footer-size)", "color: var(--rui-muted-foreground)",
    "white-space: nowrap", "overflow: hidden", "text-overflow: ellipsis", "min-height: 18px",
    "line-height: 18px", "border-top: 1px solid var(--rui-border)", "background: var(--tuzi-header-background)",
  ]
}

///|
fn status_style() -> Array[String] {
  [
    "flex: 1 1 240px", "min-width: 0", "max-width: 100%", "min-height: 32px", "display: flex",
    "align-items: center", "gap: 8px", "overflow: hidden", "color: var(--rui-muted-foreground)",
  ]
}

///|
fn help_list_style() -> Array[String] {
  [
    "display: grid", "grid-template-columns: max-content minmax(0, 1fr)", "column-gap: 12px",
  ]
}

///|
fn help_row_style() -> Array[String] {
  [
    "display: grid", "grid-column: 1 / -1", "grid-template-columns: subgrid", "margin: 5px 0",
    "align-items: baseline", "line-height: 1.5",
  ]
}

///|
fn status_text_style() -> Array[String] {
  [
    "min-width: 0", "white-space: nowrap", "overflow: hidden", "text-overflow: ellipsis",
  ]
}
