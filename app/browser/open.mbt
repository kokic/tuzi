///|
fn Model::open_default(
  model : Model,
  target : OpenTarget,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.openers is Some(registry) else { return (model, @rabbita.none) }
  let association = registry.for_entry(
    target.entry.name,
    is_dir=target.entry.is_dir(),
  )
  model.execute_opener(target, association.default_opener, emit)
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
    is_dir=target.entry.is_dir(),
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
