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
/// Keep separate locations for different server base directories on this origin.
fn location_storage_key(base : Path) -> String {
  "tuzi.location:" + base.to_string()
}

///|
fn read_browser_location(base : Path) -> BrowserLocation? raise {
  let value : @js.Value = @js.Error_::wrap(() => {
    let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
    storage.apply_with_string("getItem", [location_storage_key(base)])
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
/// Missing, invalid, or unavailable storage falls back to the server base.
fn load_browser_location(base : Path) -> BrowserLocation {
  let saved = read_browser_location(base) catch { _ => None }
  saved.unwrap_or({
    left: base.to_string(),
    right: base.to_string(),
    active: 0,
  })
}

///|
fn Model::save_browser_location(model : Model) -> Cmd {
  let key = location_storage_key(model.base)
  let value = ToJson::to_json(model.browser_location()).stringify()
  @rabbita.effect(() => {
    @js.Error_::wrap(
      () => {
        let storage : @js.Value = @js.globalThis.get_with_string("localStorage")
        storage.apply_with_string("setItem", [key, value])
      },
      map_ok=_ => (),
    ) catch {
      // Storage restrictions must not interrupt directory navigation.
      _ => ()
    }
  })
}
