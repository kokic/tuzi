///|
priv suberror KeyboardSubscription {
  OnKeyDown((@dom.KeyboardEvent) -> Cmd)
}

///|
let keyboard_subscription_loader : @sub.SubLoader = @sub.SubLoader((
  payload,
  scheduler,
) => {
  guard payload is KeyboardSubscription::OnKeyDown(callback) else {
    return None
  }
  let handler = Ref(callback)
  let target = @dom.document().as_event_target()
  let listener : @dom.Listener = event => {
    guard event.to_keyboard_event() is Some(keyboard) else { return }
    scheduler.add((handler.val)(keyboard))
  }
  target.add_event_listener("keydown", listener)
  Some({
    unload: _ => target.remove_event_listener("keydown", listener),
    update_tagger: payload => {
      guard payload is KeyboardSubscription::OnKeyDown(callback) else { return }
      handler.val = callback
    },
  })
})

///|
fn Model::keyboard_command(
  model : Model,
  event : @dom.KeyboardEvent,
  emit : Emit[Msg],
) -> Cmd {
  guard !event.is_composing() else { return @rabbita.none }
  if model.dialog == None &&
    !event.ctrl_key() &&
    !event.meta_key() &&
    !event.alt_key() {
    match event.key() {
      "Tab" => event.prevent_default()
      " " if !model.editing => event.prevent_default()
      "Escape" if model.editing => event.prevent_default()
      _ => ()
    }
  }
  emit(Key(event))
}

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
        "Escape" => ({ ..model, editing: false, }, blur_filter_input())
        "Tab" => (model.switch_active_pane(), blur_filter_input())
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
        "n" => (model, emit(MkdirOpen))
        "c" => model.transfer_selection_to_other_pane(Copy, emit)
        "m" => model.transfer_selection_to_other_pane(Move, emit)
        "y" => model.copy_selected_paths_to_clipboard(emit)
        "s" => (model, emit(SortCycle))
        "f" => (model, focus_filter_input())
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

///|
/// Set editing only through the input's real focus/blur events. Defer focus
/// until the triggering key has completed its default browser action.
fn focus_filter_input() -> Cmd {
  @rabbita.delay(
    @rabbita.effect(() => {
      guard @dom.document().get_element_by_id("filter-input").to_option()
        is Some(element) &&
        element.to_html_element() is Some(input) else {
        return
      }
      input.focus()
    }),
    0,
  )
}

///|
fn blur_filter_input() -> Cmd {
  @rabbita.effect(() => {
    guard @dom.document().get_element_by_id("filter-input").to_option()
      is Some(element) &&
      element.to_html_element() is Some(input) else {
      return
    }
    input.blur()
  })
}

///|
fn Model::move_active_pane_cursor(model : Model, delta : Int) -> Model {
  {
    ..model,
    panes: set_pane(
      model.panes,
      model.active,
      model
      .pane_at(model.active)
      .move_cursor(delta, filter?=model.entry_filter()),
    ),
  }
}

///|
fn Model::toggle_selection_and_advance_cursor(model : Model) -> Model {
  {
    ..model,
    panes: set_pane(
      model.panes,
      model.active,
      model
      .pane_at(model.active)
      .toggle_cursor_selection(filter?=model.entry_filter()),
    ),
  }
}

///|
fn Model::switch_active_pane(model : Model) -> Model {
  { ..model.with_filter(""), active: model.active.other(), editing: false, }
}
