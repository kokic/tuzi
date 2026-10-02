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
    ("Copy to other pane", "c", TransferSelection(Copy)),
    ("Move to other pane", "m", TransferSelection(Move)),
    ("Rename…", "r", RenameOpen),
    ("Copy path", "y", CopyPaths),
    ("Compress to ZIP…", "z", ZipOpen),
    ("Information", "i", InfoOpen),
    ("New directory…", "n", MkdirOpen),
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
          @rui.context_menu_shortcut(@rui.kbd(style=[UI_FONT_STYLE], shortcut)),
        ])
      }),
      @rui.context_menu_separator(),
      @rui.context_menu_item(
        scope,
        destructive=true,
        on_select=action_emit(DeleteOpen),
        [
          span("Delete…"),
          @rui.context_menu_shortcut(@rui.kbd(style=[UI_FONT_STYLE], "d")),
        ],
      ),
    ],
  )
}
