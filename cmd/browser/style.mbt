///|
fn application_style() -> Array[String] {
  [
    "display: flex", "flex-direction: column", "flex: 1", "min-height: 0", "min-width: 0",
    "margin: 8px",
  ]
}

///|
fn toolbar_style() -> Array[String] {
  [
    "flex: none", "display: flex", "flex-wrap: wrap", "align-items: center", "gap: 8px",
    "padding: 6px 12px",
  ]
}

///|
fn count_style(active : Bool) -> Array[String] {
  if active {
    ["font-weight: 700"]
  } else {
    ["font-weight: 600", "color: var(--rui-muted-foreground)"]
  }
}

///|
fn panes_style() -> Array[String] {
  ["flex: 1", "min-height: 0", "display: flex"]
}

///|
fn pane_style(active : Bool, idx : PaneSide) -> Array[String] {
  [
    "flex: 1",
    "min-width: 0",
    "display: flex",
    "flex-direction: column",
    "min-height: 0",
    ..match idx {
      Left =>
        [
          "border-top-left-radius: var(--rui-radius)", "border-bottom-left-radius: var(--rui-radius)",
        ]
      Right =>
        [
          "border-top-right-radius: var(--rui-radius)", "border-bottom-right-radius: var(--rui-radius)",
        ]
    },
    ..if active {
      ["outline: 2px solid var(--rui-ring)", "outline-offset: -2px"]
    } else {
      ["outline: 1px solid var(--rui-border)", "outline-offset: -1px"]
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
    "padding: 2px 0 2px 8px",
    "--rui-ghost-hover-bg: light-dark(var(--rui-accent), color-mix(in oklab, var(--rui-primary) 24%, var(--rui-background)))",
    ..if active {
      [
        "background: color-mix(in oklab, var(--rui-primary) 8%, var(--rui-background))",
      ]
    },
  ]
}

///|
fn pane_list_style() -> Array[String] {
  [
    "flex: 1", "display: grid", "grid-template-columns: max-content max-content max-content minmax(0, 1fr)",
    "column-gap: 6px", "align-content: start", "overflow-y: auto", "margin: 0", "padding: 0 0",
    "list-style: none",
  ]
}

///|
fn pane_status_style() -> Array[String] {
  ["padding: 8px"]
}

///|
fn row_style(is_cursor : Bool) -> Array[String] {
  [
    "display: grid",
    "grid-column: 1 / -1",
    "grid-template-columns: subgrid",
    "align-items: center",
    "min-width: 0",
    "padding: 3px 8px",
    "cursor: pointer",
    // Only the filename child opts back into text selection.
    "-webkit-user-select: none",
    "user-select: none",
    "line-height: var(--tuzi-entry-line-height)",
    ..if is_cursor {
      ["background: var(--rui-accent)", "color: var(--rui-accent-foreground)"]
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
    "flex: none", "padding: 2px 8px", "font-size: var(--tuzi-footer-size)", "color: var(--rui-muted-foreground)",
    "white-space: nowrap", "overflow: hidden", "text-overflow: ellipsis",
  ]
}

///|
fn status_style() -> Array[String] {
  [
    "flex: 1 1 240px", "min-width: 0", "max-width: 100%", "min-height: 32px", "display: flex",
    "align-items: center", "gap: 8px", "overflow: hidden",
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
