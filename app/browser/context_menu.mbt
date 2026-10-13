///|
/// Reuse the row's right-click handler so actions and menu focus stay identical.
fn Model::open_cursor_context_menu(model : Model) -> Cmd {
  let pane = model.pane_at(model.active)
  guard pane.view_data(filter?=model.entry_filter(model.active)).cursor_index
    is Some(row) else {
    return @rabbita.none
  }
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
  #|     clientX: rect.left + 8,
  #|     clientY: rect.top + 8,
  #|   }));
  #| }

///|
fn entry_menu_content(
  scope : @rui.ContextMenuScope,
  target : OpenTarget,
  openers : @tuzi.OpenRegistry?,
  emit : Emit[Msg],
  action_emit : Emit[Msg],
  transfer_disabled~ : Bool,
) -> Html {
  let open_items = openers.map_or([], registry => {
    open_with_items(scope, target, registry, emit)
  })
  let root = target.path.dirname() == target.path
  let actions : Array[(String, String, Msg)] = [
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

///|
fn Model::execute_entry_action(
  model : Model,
  idx : PaneSide,
  view_id : Int32,
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

///|
/// Capture explicit targets so breadcrumb actions never depend on row selection.
priv struct FileActionContext {
  items : Array[OpenTarget]
  cursor : OpenTarget?
  directory : Path
  selection : SelectionSubmission?
}

///|
fn Model::file_action_context(model : Model) -> FileActionContext {
  let pane = model.pane_at(model.active)
  let target = (entry : Entry) => OpenTarget::{
    pane: model.active,
    path: pane.path.join(Path("./\{entry.name}")),
    entry,
  }
  let items = pane.selected_items(filter?=model.entry_filter(model.active))
  {
    items: items.map(target),
    cursor: pane
    .cursor_entry(filter?=model.entry_filter(model.active))
    .map(target),
    directory: pane.path,
    selection: Some({
      pane: model.active,
      view_id: pane.id,
      selected: pane.selected,
      names: items.map(item => item.name),
    }),
  }
}

///|
fn Model::execute_file_action(
  model : Model,
  action : Msg,
  context : FileActionContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  match action {
    DeleteOpen => (model.open_delete_dialog(context), @rabbita.none)
    InfoOpen => model.open_info_dialog(context, emit)
    TransferSelection(kind) =>
      model.transfer_selection_to_other_pane(kind, context, emit)
    CopyPaths => model.copy_selected_paths_to_clipboard(context, emit)
    RenameOpen => model.open_rename_dialog(context, emit)
    ZipOpen => (model.open_archive_dialog(context), @rabbita.none)
    NewEntryOpen =>
      (model.open_new_entry_dialog(context.directory), @rabbita.none)
    _ => (model, @rabbita.none)
  }
}
