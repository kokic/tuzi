///|
#derive(Eq)
priv enum MarkdownView {
  Preview
  Code
}

///|
#derive(Eq)
priv enum MarkdownContent {
  Loading
  Loaded(Result[String, String])
}

///|
#derive(Eq)
priv struct MarkdownContext {
  id : Int32
  path : Path
  pane : PaneSide
  view : MarkdownView
  content : MarkdownContent
  fragment : String?
  link_request : Int32
}

///|
priv enum MarkdownMsg {
  Loaded(Int32, Result[String, String])
  ViewChanged(MarkdownView)
  LinkClicked(Int32, MarkdownLink)
  LinkLoaded(Int32, Int32, MarkdownLink, Result[Entry, RequestFailure])
}

///|
fn Model::open_markdown(
  model : Model,
  path : Path,
  pane : PaneSide,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let id = model.dialog_revision + 1
  (
    {
      ..model,
      dialog: Markdown({
        id,
        path,
        pane,
        view: Preview,
        content: Loading,
        fragment: None,
        link_request: 0,
      }),
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
fn Model::update_markdown(
  model : Model,
  msg : MarkdownMsg,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.dialog is Markdown(context) else { return (model, @rabbita.none) }
  match msg {
    Loaded(id, result) => {
      guard id == context.id else { return (model, @rabbita.none) }
      let context = { ..context, content: Loaded(result), }
      ({ ..model, dialog: Markdown(context), }, context.scroll_to_fragment())
    }
    ViewChanged(view) => {
      let context = { ..context, view, }
      ({ ..model, dialog: Markdown(context), }, context.scroll_to_fragment())
    }
    LinkClicked(id, link) => {
      guard id == context.id else { return (model, @rabbita.none) }
      let request = context.link_request + 1
      let context = { ..context, link_request: request, }
      if link.path == context.path && link.fragment is Some(_) {
        let context = { ..context, fragment: link.fragment, }
        return (
          { ..model, dialog: Markdown(context), },
          context.scroll_to_fragment(),
        )
      }
      (
        { ..model, dialog: Markdown(context), },
        request_api(
          "/api/entry",
          body=ToJson::to_json(@tuzi.DirectoryRequest::{ path: link.path, }),
          result => emit(MarkdownEvent(LinkLoaded(id, request, link, result))),
        ),
      )
    }
    LinkLoaded(id, request, link, result) => {
      guard id == context.id && request == context.link_request else {
        return (model, @rabbita.none)
      }
      match result {
        Err(error) =>
          (
            model,
            emit(
              Toast(
                "Cannot open link",
                Some(error.message()),
                @rui.ToastDestructive,
              ),
            ),
          )
        Ok(entry) => {
          let (model, command) = model.open_default(
            { pane: context.pane, path: link.path, entry, },
            emit,
          )
          let model = if model.dialog is Markdown(next) && next.id != id {
            { ..model, dialog: Markdown({ ..next, fragment: link.fragment, }), }
          } else {
            model
          }
          (model, command)
        }
      }
    }
  }
}
