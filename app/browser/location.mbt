///|
priv struct BrowserLocation {
  left : String
  right : String
  active : Int
} derive(ToJson, @json.FromJson)

///|
fn Model::browser_location(model : Model) -> BrowserLocation {
  {
    left: model.panes.0.current.path.to_string(),
    right: model.panes.1.current.path.to_string(),
    active: model.active.index(),
  }
}

///|
fn read_browser_location() -> BrowserLocation? raise {
  let value : @js.Value = @js.Error_::wrap(() => {
    let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
    storage.apply_with_string("getItem", [LocationStorageKey])
  })
  guard value.is_string() else { return None }
  let location : BrowserLocation = @json.from_json(
    @json.parse(value.to_string()),
  )
  guard (location.active == 0 || location.active == 1) &&
    !location.left.is_empty() &&
    !location.right.is_empty() else {
    return None
  }
  Some(location)
}

///|
/// Explicit paths skip history. Restoring without usable storage falls back to base.
fn load_browser_location(
  base : Path,
  startup : @tuzi.StartupMode,
) -> BrowserLocation {
  let saved : BrowserLocation? = match startup {
    OpenDirectory => None
    RestoreHistory => read_browser_location() catch { _ => None }
  }
  saved.unwrap_or({
    left: base.to_string(),
    right: base.to_string(),
    active: 0,
  })
}

///|
fn Model::save_browser_location(model : Model) -> Cmd {
  let value = ToJson::to_json(model.browser_location()).stringify()
  @rabbita.effect(() => {
    @js.Error_::wrap(
      () => {
        let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
        storage.apply_with_string("setItem", [LocationStorageKey, value])
      },
      map_ok=_ => (),
    ) catch {
      // Storage restrictions must not interrupt directory navigation.
      _ => ()
    }
  })
}
