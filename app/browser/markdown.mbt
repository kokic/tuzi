///|
priv enum MarkdownView {
  Preview
  Code
} derive(Eq)

///|
priv enum MarkdownContent {
  Loading
  Loaded(Result[String, String])
} derive(Eq)

///|
priv struct MarkdownContext {
  id : Int32
  path : Path
  view : MarkdownView
  content : MarkdownContent
} derive(Eq)

///|
priv enum MarkdownMsg {
  Loaded(Int32, Result[String, String])
  ViewChanged(MarkdownView)
}

///|
fn Model::open_markdown(
  model : Model,
  path : Path,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let id = model.dialog_revision + 1
  (
    {
      ..model,
      dialog: Markdown({ id, path, view: Preview, content: Loading, }),
      dialog_error: "",
    },
    @rabbita.perform(result => emit(MarkdownEvent(Loaded(id, result))), () => {
      try {
        let (response, data) = @http.get(
          @dom.window().origin() + path.file_url(),
        )
        guard response.code is (200..<300) else {
          return Err("HTTP \{response.code} \{response.reason}")
        }
        Ok(data.text())
      } catch {
        error => Err(error.to_string())
      }
    }),
  )
}

///|
fn Model::update_markdown(model : Model, msg : MarkdownMsg) -> Model {
  guard model.dialog is Markdown(context) else { return model }
  let context = match msg {
    Loaded(id, result) => {
      guard id == context.id else { return model }
      { ..context, content: Loaded(result), }
    }
    ViewChanged(view) => { ..context, view, }
  }
  { ..model, dialog: Markdown(context), }
}

///|
fn MarkdownContext::resolve_link(
  context : MarkdownContext,
  destination : String,
) -> String {
  guard !destination.is_empty() &&
    !destination.has_prefix("/") &&
    !destination.has_prefix("#") else {
    return destination
  }
  let (reference, fragment) = destination
    .split_once("#")
    .map_or((destination[:], ""), pair => (pair.0, "#\{pair.1}"))
  let (path, query) = reference
    .split_once("?")
    .map_or((reference, ""), pair => (pair.0, "&\{pair.1}"))
  let first_segment = path.split_once("/").map_or(path, pair => pair.0)
  guard !first_segment.contains(":") else { return destination }
  let path = @percent.decode(path) catch { _ => return destination }
  let target = {
    guard !path.is_empty() else { context.path }
    context.path.dirname().join(Path("./\{path}"))
  }
  target.file_url() + query + fragment
}
