///|
/// Keep the item's path with the action, independent of the current cursor.
priv struct OpenTarget {
  pane : PaneSide
  path : Path
  entry : Entry
}

///|
fn Model::cursor_open_target(model : Model) -> OpenTarget? {
  let pane = model.pane_at(model.active)
  let data = pane.view_data(filter?=model.entry_filter())
  data.entries
  .get(data.cursor_index.unwrap_or(0))
  .map(entry => {
    pane: model.active,
    path: pane.path.join(Path("./\{entry.name}")),
    entry,
  })
}

///|
fn Model::open_default(
  model : Model,
  target : OpenTarget,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.openers is Some(registry) else { return (model, @rabbita.none) }
  let association = registry.for_entry(
    target.entry.name,
    is_dir=target.entry.is_dir,
  )
  model.execute_opener(target, association.default_opener, emit)
}

///|
fn OpenTarget::unavailable_reason(
  self : OpenTarget,
  action : @tuzi.OpenAction,
) -> String? {
  match action {
    Browse =>
      if self.entry.is_dir {
        None
      } else {
        Some("Select a directory to enter.")
      }
    Preview => {
      guard !self.entry.is_dir else {
        return Some("Directories cannot be previewed as files.")
      }
      // Missing listing metadata is checked by the existing file endpoint.
      guard self.entry.size.map_or(true, size => {
        preview_content_type(self.path, size) is Some(_)
      }) else {
        return Some(
          "Unknown formats can only be opened as text when at most 1 MiB.",
        )
      }
      None
    }
    ExtractZip => {
      guard !self.entry.is_dir && self.entry.name.to_lower().has_suffix(".zip") else {
        return Some("Select a ZIP file to extract.")
      }
      None
    }
    External => None
  }
}

///|
fn Model::execute_opener(
  model : Model,
  target : OpenTarget,
  id : String,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.openers is Some(registry) &&
    registry.openers.get(id) is Some(opener) else {
    return (model, @rabbita.none)
  }
  let association = registry.for_entry(
    target.entry.name,
    is_dir=target.entry.is_dir,
  )
  guard association.openers.contains(id) else { return (model, @rabbita.none) }
  if target.unavailable_reason(opener.action) is Some(reason) {
    return (
      model,
      emit(Toast("Cannot open file", Some(reason), @rui.ToastDestructive)),
    )
  }
  let model = { ..model, dialog: None, dialog_error: "", }
  match opener.action {
    Browse => model.navigate_to_directory(target.pane, target.path)
    Preview if target.entry.name.to_lower().has_suffix(".md") ||
      target.entry.name.to_lower().has_suffix(".markdown") =>
      model.open_markdown(target.path, emit)
    Preview =>
      (
        model,
        @rabbita.effect(() => {
          let window = @dom.Window::from(@dom.window())
          let opened : @js.Value = window.apply_with_string("open", [
            target.path.file_url(),
            "_blank",
            "noopener",
          ])
          ignore(opened)
        }),
      )
    ExtractZip => {
      let name = target.entry.name
      let stem = name.view(end_offset=name.length() - 4).to_owned()
      let directory = if stem.is_empty() { "archive" } else { stem }
      (
        {
          ..model,
          dialog: UnzipInput(
            source=target.path,
            input=target.path.dirname().join(Path("./\{directory}")).to_string(),
          ),
        },
        @rabbita.none,
      )
    }
    External =>
      (
        model,
        request_api(
          "/api/open",
          body=ToJson::to_json(@tuzi.OpenRequest::{
            path: target.path,
            opener: id,
          }),
          (result : Result[Unit, RequestFailure]) => {
            match result {
              Ok(_) => @rabbita.none
              Err(error) =>
                emit(
                  Toast(
                    opener.label + " failed",
                    Some(error.message()),
                    @rui.ToastDestructive,
                  ),
                )
            }
          },
        ),
      )
  }
}

///|
fn open_with_items(
  scope : @rui.ContextMenuScope,
  target : OpenTarget,
  registry : @tuzi.OpenRegistry,
  emit : Emit[Msg],
) -> Array[Html] {
  let association = registry.for_entry(
    target.entry.name,
    is_dir=target.entry.is_dir,
  )
  let items : Array[Html] = []
  for id in association.openers {
    let opener = registry.openers[id]
    guard target.unavailable_reason(opener.action) is None else { continue }
    items.push(
      @rui.context_menu_item(
        scope,
        on_select=emit(OpenWith(target, id)),
        opener.label,
      ),
    )
  }
  items
}
