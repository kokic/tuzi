///|
fn entry_menu_content(
  scope : @rui.ContextMenuScope,
  item : EntryRow,
  idx : PaneSide,
  openers : @tuzi.OpenRegistry?,
  emit : Emit[Msg],
) -> Html {
  let target : OpenTarget = {
    pane: idx,
    path: Path(item.directory).join(Path("./\{item.entry.name}")),
    entry: item.entry,
  }
  let open_items = openers.map_or([], registry => {
    open_with_items(scope, target, registry, emit)
  })
  // Resolve the clicked file and run the existing action in one model update.
  let action_emit = emit.map(action => {
    EntryAction(idx, item.view_id, item.entry.name, action)
  })
  let actions : Array[(String, String, Msg)] = [
    ..if !item.entry.kind.is_link() {
      [
        ("Copy to other pane", "c", TransferSelection(Copy)),
        ("Move to other pane", "m", TransferSelection(Move)),
        ("Rename…", "r", RenameOpen),
      ]
    },
    ("Copy path", "y", CopyPaths),
    ..if !item.entry.kind.is_link() {
      [("Compress to ZIP…", "z", ZipOpen)]
    },
    ("Information", "i", InfoOpen),
    ("New file or folder…", "n", NewEntryOpen),
  ]
  @rui.context_menu_content(
    scope,
    aria_label="File actions",
    style=[UI_FONT_STYLE],
    [
      ..open_items,
      ..if !open_items.is_empty() {
        [@rui.context_menu_separator()]
      },
      ..actions.map(action => {
        let (label, shortcut, message) = action
        @rui.context_menu_item(scope, on_select=action_emit(message), [
          span(label),
          @rui.context_menu_shortcut(kbd(shortcut)),
        ])
      }),
      @rui.context_menu_separator(),
      @rui.context_menu_item(
        scope,
        destructive=true,
        on_select=action_emit(DeleteOpen),
        [span("Delete…"), @rui.context_menu_shortcut(kbd("d"))],
      ),
    ],
  )
}

///|
fn Model::execute_entry_action(
  model : Model,
  idx : PaneSide,
  view_id : Int,
  name : String,
  action : Msg,
  emit : Emit[Msg],
  toast_send : Ref[ToastSender?],
) -> (Model, Cmd) {
  let pane = model.pane_at(idx)
  guard pane.id == view_id &&
    pane
    .visible_entries(filter?=model.entry_filter(idx))
    .any(entry => entry.name == name) else {
    return (model, @rabbita.none)
  }
  let pane = {
    ..pane,
    cursor: Some(name),
    selected: if pane.selected.contains(name) {
      pane.selected
    } else {
      Set([])
    },
  }
  let model = { ..model, active: idx, panes: set_pane(model.panes, idx, pane), }
  model.update_message(action, emit, toast_send)
}
