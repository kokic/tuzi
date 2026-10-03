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
  // Marker data depends on icon mode. Keep this at the update boundary so
  // every configuration change invalidates listings, including future controls.
  let updated = if updated.icons != model.icons {
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
    BaseLoaded(config) => {
      let location = load_browser_location(config.base, config.startup)
      let left = Path(location.left)
      let right = Path(location.right)
      let updated = {
        ..model,
        startup: Started,
        theme: config.theme,
        icons: config.icons,
        openers: Some(config.openers),
        supports_drive_selection: config.supports_drive_selection,
        active: if location.active == 0 {
          Left
        } else {
          Right
        },
        panes: (model.panes.0.navigate(left), model.panes.1.navigate(right)),
      }
      (updated, updated.save_browser_location())
    }
    PaneEvent(msg) => model.update_panes(msg, emit)
    Key(kb) => model.handle_keyboard_event(kb, emit)
    SortCycle => (model.cycle_sort_order(), @rabbita.none)
    ThemeToggle => {
      let theme : Theme = match model.theme {
        Light => Dark
        Dark => Light
      }
      ({ ..model, theme, }, @rabbita.none)
    }
    FilterFocus(idx, focused) => {
      let model = if focused {
        { ..model, active: idx, editing: true, }
      } else if model.active == idx {
        { ..model, editing: false, }
      } else {
        model
      }
      (model, @rabbita.none)
    }
    DeleteOpen => (model.open_delete_dialog(), @rabbita.none)
    InfoOpen => model.open_info_dialog(emit)
    OpenWith(target, id) => model.execute_opener(target, id, emit)
    EntryAction(idx, view_id, name, action) => {
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
      let model = {
        ..model,
        active: idx,
        panes: set_pane(model.panes, idx, pane),
      }
      model.update_message(action, emit, toast_send)
    }
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
    ZipLevelChanged(value) => {
      guard model.dialog is ZipInput(directory~, names~, input~, ..) else {
        return (model, @rabbita.none)
      }
      let level = @string.parse_int(value, base=10) catch {
        _ => return (model, @rabbita.none)
      }
      guard level >= 0 && level <= 9 else { return (model, @rabbita.none) }
      (
        {
          ..model,
          dialog: ZipInput(directory~, names~, input~, level~),
          dialog_error: "",
        },
        @rabbita.none,
      )
    }
    ActivityOpen =>
      ({ ..model, dialog: Activity, dialog_error: "", }, @rabbita.none)
    NewEntryOpen =>
      (
        {
          ..model,
          dialog: NewEntryInput(
            directory=model.pane_at(model.active).path,
            input="",
          ),
          dialog_error: "",
        },
        @rabbita.none,
      )
    NewEntrySubmit(kind) => model.submit_dialog(emit, new_entry_kind=kind)
    HelpOpen => ({ ..model, dialog: Help, dialog_error: "", }, @rabbita.none)
    FilterChanged(idx, text) => (model.with_filter(idx, text), @rabbita.none)
    DialogInput(text) =>
      (
        { ..model, dialog: model.dialog.with_input(text), dialog_error: "", },
        @rabbita.none,
      )
    DialogCancel => {
      // The native dialog has already closed and raised its close event. Going
      // back to the Git panel keeps a dialog open, so reopen the host element.
      let dialog = match model.dialog {
        GitRenameInput(context~, ..) => GitInfo(context)
        _ => None
      }
      let command = if dialog is GitInfo(_) {
        @dialog.show(DialogId)
      } else {
        @rabbita.none
      }
      ({ ..model, dialog, dialog_error: "", }, command)
    }
    DialogSubmit => model.submit_dialog(emit)
    DragStart(idx, name) => {
      let pane = model.pane_at(idx)
      let names = if pane.selected.contains(name) {
        pane
        .selected_items(filter?=model.entry_filter(idx))
        .map(entry => entry.name)
      } else {
        [name]
      }
      (
        {
          ..model,
          dragging: Some({ source_pane: idx, directory: pane.path, names, }),
        },
        @rabbita.none,
      )
    }
    Drop(idx) => model.copy_dropped_entries(idx, emit)
    DragEnd => ({ ..model, dragging: None, }, @rabbita.none)
    Toast(title, description, variant) =>
      (
        model,
        toast_send.val.map_or(@rabbita.none, send => {
          send(title, description, variant)
        }),
      )
  }
}

///|
fn Model::subscriptions(model : Model, emit : Emit[Msg]) -> @sub.Sub {
  @sub.custom_sub(
    "keyboard",
    Local,
    KeyboardSubscription::OnKeyDown(event => model.keyboard_command(event, emit)),
    keyboard_subscription_loader,
  )
}

///|
fn Model::navigate_to_directory(
  model : Model,
  idx : PaneSide,
  path : Path,
) -> (Model, Cmd) {
  let updated = {
    ..model,
    active: idx,
    panes: match idx {
      Left => (model.panes.0.navigate(path), model.panes.1)
      Right => (model.panes.0, model.panes.1.navigate(path))
    },
  }
  (updated, updated.save_browser_location())
}

///|
fn Model::pane_at(model : Model, idx : PaneSide) -> Pane {
  match idx {
    Left => model.panes.0.current
    Right => model.panes.1.current
  }
}

///|
fn set_pane(
  panes : (PaneStack, PaneStack),
  idx : PaneSide,
  pane : Pane,
) -> (PaneStack, PaneStack) {
  match idx {
    Left => ({ ..panes.0, current: pane, }, panes.1)
    Right => (panes.0, { ..panes.1, current: pane, })
  }
}
