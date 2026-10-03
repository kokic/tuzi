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
  id : Int
  path : Path
  view : MarkdownView
  content : MarkdownContent
} derive(Eq)

///|
priv enum MarkdownMsg {
  Loaded(Int, Result[String, String])
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
      // A closed or replaced preview cannot receive an earlier file's response.
      guard id == context.id else { return model }
      { ..context, content: Loaded(result), }
    }
    ViewChanged(view) => { ..context, view, }
  }
  { ..model, dialog: Markdown(context), }
}
