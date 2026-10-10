///|
fn read_browser_theme() -> Theme? raise {
  let value : @js.Value = @js.Error_::wrap(() => {
    let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
    storage.apply_with_string("getItem", [ThemeStorageKey])
  })
  guard value.is_string() else { return None }
  match value.to_string() {
    "light" => Some(Light)
    "dark" => Some(Dark)
    _ => None
  }
}

///|
fn save_browser_theme(theme : Theme) -> Cmd {
  let value = theme.to_string()
  @rabbita.effect(() => {
    @js.Error_::wrap(
      () => {
        let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
        storage.apply_with_string("setItem", [ThemeStorageKey, value])
      },
      map_ok=_ => (),
    ) catch {
      // Storage restrictions must not interrupt theme switching.
      _ => ()
    }
  })
}
