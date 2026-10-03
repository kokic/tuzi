///|
fn Model::handle_keyboard_event(
  model : Model,
  kb : @dom.KeyboardEvent,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let key = kb.key()
  match () {
    _ if model.dialog != None => {
      guard !kb.ctrl_key() &&
        !kb.meta_key() &&
        !kb.alt_key() &&
        !kb.is_composing() &&
        !kb.repeat() else {
        return (model, @rabbita.none)
      }
      match key {
        "Enter" => model.submit_dialog(emit)
        _ => (model, @rabbita.none)
      }
    }
    _ if model.editing =>
      match key {
        "Escape" =>
          (
            { ..model, editing: false, },
            blur_filter_input(model.active, model.pane_at(model.active).id),
          )
        "Tab" =>
          (
            model.switch_active_pane(),
            blur_filter_input(model.active, model.pane_at(model.active).id),
          )
        _ => (model, @rabbita.none)
      }
    _ if kb.ctrl_key() || kb.meta_key() || kb.alt_key() =>
      (model, @rabbita.none)
    _ =>
      match key {
        "ArrowDown" => {
          let updated = model.move_active_pane_cursor(1)
          (updated, updated.scroll_to_cursor())
        }
        "ArrowUp" => {
          let updated = model.move_active_pane_cursor(-1)
          (updated, updated.scroll_to_cursor())
        }
        "ArrowRight" => (model.switch_active_pane(), @rabbita.none)
        "ArrowLeft" => (model.switch_active_pane(), @rabbita.none)
        "Enter" if !kb.repeat() && !kb.is_composing() =>
          model.open_cursor_entry(emit)
        "Escape" => model.open_parent_directory()
        "Tab" => (model.switch_active_pane(), @rabbita.none)
        " " => {
          let updated = model.toggle_selection_and_advance_cursor()
          (updated, updated.scroll_to_cursor())
        }
        "d" => (model, emit(DeleteOpen))
        "i" => (model, emit(InfoOpen))
        "r" => (model, emit(RenameOpen))
        "z" => (model, emit(ZipOpen))
        "n" => (model, emit(NewEntryOpen))
        "c" => (model, emit(TransferSelection(Copy)))
        "m" => (model, emit(TransferSelection(Move)))
        "y" => (model, emit(CopyPaths))
        "s" => (model, emit(SortCycle))
        "f" =>
          (
            model,
            focus_filter_input(model.active, model.pane_at(model.active).id),
          )
        "?" => (model, emit(HelpOpen))
        _ => (model, @rabbita.none)
      }
  }
}

///|
/// Handle Enter inside a dialog: let buttons, links, and selects activate
/// natively, and submit explicitly for other targets. Stop propagation so the
/// global Enter (open entry) never fires, and swallow IME/repeat Enter so a
/// single keypress cannot submit twice.
fn handle_dialog_keyboard_event(
  event : @dom.KeyboardEvent,
  emit : Emit[Msg],
) -> Cmd {
  let key = event.key()
  guard !event.is_composing() &&
    !event.repeat() &&
    !event.ctrl_key() &&
    !event.meta_key() &&
    !event.alt_key() else {
    event.stop_propagation()
    if key == "Enter" {
      event.prevent_default()
    }
    return @rabbita.none
  }
  let target = event.target().to_element()
  match key {
    "Enter" => {
      event.stop_propagation()
      guard !target.map_or(false, element => {
        element.closest("button, a[href], select") is Some(_)
      }) else {
        return @rabbita.none
      }
      event.prevent_default()
      emit(DialogSubmit)
    }
    _ => @rabbita.none
  }
}
