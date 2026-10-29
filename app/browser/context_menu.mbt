///|
fn Model::open_cursor_context_menu(model : Model) -> Cmd {
  let pane = model.pane_at(model.active)
  guard pane.cursor_index() is Some(row) else { return @rabbita.none }
  let id = "pane-\{model.active.index()}-view-\{pane.id}-row-\{row}-open-trigger"
  @cmd.custom_cmd(kind=AfterRender, _ => {
    guard @dom.document().get_element_by_id(id).to_option() is Some(trigger) else {
      return
    }
    trigger.scroll_into_view_with_options(
      block="nearest",
      inline="nearest",
      container="nearest",
    )
    dispatch_entry_context_menu(trigger)
  })
}

///|
extern "js" fn dispatch_entry_context_menu(trigger : @dom.Element) -> Unit =
  #| (trigger) => {
  #|   const rect = trigger.getBoundingClientRect();
  #|   trigger.dispatchEvent(new MouseEvent("contextmenu", {
  #|     bubbles: true,
  #|     cancelable: true,
  #|     button: 2,
  #|     clientX: rect.left + rect.width / 3,
  #|     clientY: rect.top + 8,
  #|   }));
  #| }

///|
fn entry_menu_content(
  scope : @rui.ContextMenuScope,
  target : OpenTarget,
  openers : @tuzi.OpenRegistry?,
  emit : Emit[Msg],
  action_emit : Emit[FileAction],
  transfer_disabled~ : Bool,
) -> Html {
  let open_items = openers.map_or([], registry => {
    open_with_items(scope, target, registry, emit)
  })
  let root = target.path.dirname() == target.path
  let actions : Array[(String, String, FileAction)] = [
    ..if !target.entry.is_link() {
      [
        ("Copy to other pane", "c", TransferSelection(Copy)),
        ("Move to other pane", "m", TransferSelection(Move)),
        ("Rename…", "r", RenameOpen),
      ]
    },
    ("Copy path", "y", CopyPaths),
    ..if !target.entry.is_link() {
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
      ..if !target.entry.is_link() {
        [
          @rui.context_menu_item(
            scope,
            disabled=transfer_disabled || root,
            on_select=action_emit(CreateLinkToOtherPane),
            "symbolic link to",
          ),
        ]
      },
      ..actions.map(action => {
        let (label, shortcut, message) = action
        @rui.context_menu_item(
          scope,
          disabled=(transfer_disabled && message is TransferSelection(_)) ||
            (root && message is (TransferSelection(_) | RenameOpen | ZipOpen)),
          on_select=action_emit(message),
          [span(label), @rui.context_menu_shortcut(kbd(shortcut))],
        )
      }),
      @rui.context_menu_separator(),
      @rui.context_menu_item(
        scope,
        destructive=true,
        disabled=root,
        on_select=action_emit(DeleteOpen),
        [span("Delete…"), @rui.context_menu_shortcut(kbd("d"))],
      ),
    ],
  )
}
