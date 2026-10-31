///|
priv enum SessionPreviewContent {
  Loading
  Loaded(Result[@session.Document, String])
} derive(Eq)

///|
priv struct SessionPreviewContext {
  id : Int32
  path : Path
  content : SessionPreviewContent
} derive(Eq)

///|
fn Model::open_session_preview(
  model : Model,
  path : Path,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let id = model.dialog_revision + 1
  (
    {
      ..model,
      dialog: SessionPreview({ id, path, content: Loading, }),
      dialog_error: "",
    },
    @rabbita.perform(result => emit(SessionPreviewLoaded(id, result)), () => {
      try {
        let (response, data) = @http.get(
          @dom.window().origin() + path.file_url(),
        )
        guard response.code is (200..<300) else {
          return Err("HTTP \{response.code} \{response.reason}")
        }
        @session.parse(data.text())
      } catch {
        error => Err(error.to_string())
      }
    }),
  )
}

///|
fn Model::receive_session_preview(
  model : Model,
  id : Int32,
  result : Result[@session.Document, String],
) -> Model {
  guard model.dialog is SessionPreview(context) && context.id == id else {
    return model
  }
  { ..model, dialog: SessionPreview({ ..context, content: Loaded(result), }), }
}
