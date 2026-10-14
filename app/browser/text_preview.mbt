///|
priv enum TextPreviewContent {
  Loading
  Loaded(Result[String, String])
} derive(Eq)

///|
priv struct TextPreviewContext {
  id : Int32
  path : Path
  content : TextPreviewContent
} derive(Eq)

///|
fn is_text_preview_file(name : String) -> Bool {
  let name = name.to_lower()
  [".txt", ".toml", ".yaml", ".yml", ".json", ".ini", ".conf"].any(extension => {
    name.has_suffix(extension)
  })
}

///|
fn Model::open_text_preview(
  model : Model,
  path : Path,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let id = model.dialog_revision + 1
  (
    {
      ..model,
      dialog: TextPreview({ id, path, content: Loading, }),
      dialog_error: "",
    },
    @rabbita.perform(result => emit(TextPreviewLoaded(id, result)), () => {
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
fn Model::receive_text_preview(
  model : Model,
  id : Int32,
  result : Result[String, String],
) -> Model {
  // A closed or replaced preview cannot receive an earlier file's response.
  guard model.dialog is TextPreview(context) && context.id == id else {
    return model
  }
  { ..model, dialog: TextPreview({ ..context, content: Loaded(result), }), }
}
