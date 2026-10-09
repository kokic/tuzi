///|
fn Model::update(
  model : Model,
  msg : Msg,
  emit : Emit[Msg],
  toast_send : Ref[ToastSender?],
) -> (Model, Cmd) {
  let (updated, command) = model.update_message(msg, emit, toast_send)
  let updated = if updated.dialog != model.dialog {
    { ..updated, dialog_revision: model.dialog_revision + 1, }
  } else {
    updated
  }
  // Marker data depends on entry appearance. Keep this at the update boundary so
  // every configuration change invalidates listings, including future controls.
  let updated = if updated.entry_appearance != model.entry_appearance {
    {
      ..updated,
      panes: (
        updated.panes.0.invalidate(_ => true),
        updated.panes.1.invalidate(_ => true),
      ),
    }
  } else {
    updated
  }
  let (updated, listings) = updated.load_pending_panes(emit)
  (updated, @rabbita.batch([command, listings]))
}

///|
fn Model::update_message(
  model : Model,
  msg : Msg,
  emit : Emit[Msg],
  toast_send : Ref[ToastSender?],
) -> (Model, Cmd) {
  match msg {
    BaseFailed(error) =>
      ({ ..model, startup: StartupFailed(error), }, @rabbita.none)
    BaseRetry => ({ ..model, startup: Starting, }, request_startup(emit))
    BaseLoaded(config) => model.apply_server_config(config)
    PaneEvent(msg) => model.update_panes(msg, emit)
    SyncPanePath => model.sync_other_pane_path()
    BookmarkEvent(msg) => model.update_bookmarks(msg, emit)
    Key(kb) => model.handle_keyboard_event(kb, emit)
    SortCycle(idx) => (model.cycle_sort_order(idx), @rabbita.none)
    ThemeToggle => model.toggle_theme()
    FilterFocus(idx, focused) => model.update_filter_focus(idx, focused)
    DeleteOpen => (model.open_delete_dialog(), @rabbita.none)
    InfoOpen => model.open_info_dialog(emit)
    OpenWith(target, id) => model.execute_opener(target, id, emit)
    EntryAction(idx, view_id, name, action) =>
      model.execute_entry_action(idx, view_id, name, action, emit, toast_send)
    TransferSelection(kind) =>
      model.transfer_selection_to_other_pane(kind, emit)
    CopyPaths => model.copy_selected_paths_to_clipboard(emit)
    MarkdownEvent(msg) => (model.update_markdown(msg), @rabbita.none)
    GitEvent(msg) => model.update_git(msg, emit)
    TaskEvent(msg) => model.update_tasks(msg, emit)
    RenameOpen => model.open_rename_dialog(emit)
    LinkTargetLoaded(id, result) =>
      (model.receive_link_target(id, result), @rabbita.none)
    LinkPathInput(value) =>
      (
        model.update_link_fields(fields => { ..fields, path: value, }),
        @rabbita.none,
      )
    LinkTargetInput(value) =>
      (
        model.update_link_fields(fields => { ..fields, target: Some(value), }),
        @rabbita.none,
      )
    ZipOpen => (model.open_archive_dialog(), @rabbita.none)
    ZipLevelChanged(value) => model.set_archive_compression_level(value)
    ActivityOpen =>
      ({ ..model, dialog: Activity, dialog_error: "", }, @rabbita.none)
    NewEntryOpen => (model.open_new_entry_dialog(), @rabbita.none)
    NewEntrySubmit(kind) => model.submit_dialog(emit, new_entry_kind=kind)
    HelpOpen => ({ ..model, dialog: Help, dialog_error: "", }, @rabbita.none)
    FilterChanged(idx, text) => (model.with_filter(idx, text), @rabbita.none)
    DialogInput(text) =>
      (
        { ..model, dialog: model.dialog.with_input(text), dialog_error: "", },
        @rabbita.none,
      )
    DialogCancel => model.cancel_dialog()
    DialogSubmit => model.submit_dialog(emit)
    Toast(title, description, variant) =>
      (
        model,
        toast_send.val.map_or(@rabbita.none, send => {
          send(title, description, variant)
        }),
      )
  }
}
