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
  guard !event.get_default_prevented() &&
    !event
    .target()
    .to_element()
    .map_or(false, element => element.closest("[role=menu]") is Some(_)) else {
    return @rabbita.none
  }
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
fn Model::subscriptions(model : Model, emit : Emit[Msg]) -> @sub.Sub {
  @sub.custom_sub(
    "keyboard",
    Local,
    KeyboardSubscription::OnKeyDown(event => model.keyboard_command(event, emit)),
    keyboard_subscription_loader,
  )
}
