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
    FilterFocus(focused) => ({ ..model, editing: focused, }, @rabbita.none)
    DeleteOpen => (model.open_delete_dialog(), @rabbita.none)
    InfoOpen => model.open_info_dialog(emit)
    GitEvent(msg) => model.update_git(msg, emit)
    TaskEvent(msg) => model.update_tasks(msg, emit)
    RenameOpen => model.open_rename_dialog(emit)
    ZipOpen => (model.open_archive_dialog(), @rabbita.none)
    ActivityOpen =>
      ({ ..model, dialog: Activity, dialog_error: "", }, @rabbita.none)
    MkdirOpen =>
      (
        {
          ..model,
          dialog: MkdirInput(
            directory=model.pane_at(model.active).path,
            input="",
          ),
          dialog_error: "",
        },
        @rabbita.none,
      )
    HelpOpen => ({ ..model, dialog: Help, dialog_error: "", }, @rabbita.none)
    FilterChanged(text) => (model.with_filter(text), @rabbita.none)
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
        .selected_items(filter?=model.entry_filter())
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
  ignore(model)
  @sub.batch([@sub.on_key_down(emit.map(kb => Key(kb)))])
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
