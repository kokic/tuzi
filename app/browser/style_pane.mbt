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
    "container-type: inline-size",
    "container-name: file-pane",
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
    "box-sizing: border-box",
    "min-height: var(--tuzi-row-height)",
    "border-bottom: 1px solid var(--rui-border)",
    "background: var(--rui-background)",
    ..if active {
      ["background: var(--rui-muted)"]
    },
  ]
}

///|
fn pane_list_style() -> Array[String] {
  [
    CODE_FONT_STYLE,
    "flex: 1",
    "display: grid",
    "grid-template-columns: max-content max-content minmax(0, 1fr) max-content minmax(1em, max-content) calc(var(--tuzi-time-column, 17ch) + 10px)",
    "font-size: var(--tuzi-entry-subtitle-size)",
    "column-gap: 8px",
    "align-content: start",
    "overflow-y: auto",
    "margin: 0",
    "padding: 4px 0",
    "list-style: none",
    "scrollbar-width: thin",
    "scrollbar-color: var(--rui-border) transparent",
  ]
}

///|
fn pane_status_style() -> Array[String] {
  ["padding: 20px 16px", "margin: 0", "font-size: 0.8125rem"]
}
