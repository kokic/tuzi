///|
const HelpTableCaption : String = "ONLY APPLE CAN'T DO"

///|
fn help_dialog(emit : Emit[Msg]) -> Html {
  modal("Help", emit, size=Wide, [
    @rui.table([
      @rui.table_caption(style=["color: currentColor"], HelpTableCaption),
      @rui.table_body(help_lines()),
    ]),
  ])
}

///|
fn help_lines() -> Array[Html] {
  let binds = [
    ("Tab/←/→", "switch pane"),
    ("↑↓", "move cursor"),
    ("Space", "select"),
    ("Enter", "open file / enter directory / extract ZIP"),
    ("a / Right-click", "open file / folder actions"),
    ("Esc", "up / cancel"),
    ("c/m", "copy / move to other pane"),
    ("d", "delete"),
    ("r", "rename"),
    ("i", "file / folder information"),
    ("z", "compress to ZIP"),
    ("n", "new file / folder"),
    ("s", "sort"),
    ("y", "copy path"),
    ("f", "filter active pane"),
    ("g", "go to directory"),
    ("/", "open [command]"),
    ("?", "open [help]"),
  ]
  binds.map(pair => {
    let (key, desc) = pair
    @rui.table_row([
      @rui.table_cell(style=["text-align: right"], kbd(key)),
      @rui.table_cell(style=["text-align: left", "white-space: normal"], desc),
    ])
  })
}
