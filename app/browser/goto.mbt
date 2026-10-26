///|
priv struct GotoContext {
  pane : PaneSide
  directory : Path
  input : String
  pending : Bool
} derive(Eq)

///|
priv enum GotoMsg {
  Open(PaneSide, Path)
  Loaded(Int32, Path, Bool, Result[Array[Entry], RequestFailure])
}

///|
fn Model::update_goto(model : Model, msg : GotoMsg) -> (Model, Cmd) {
  match msg {
    Open(pane, directory) =>
      (
        {
          ..model,
          dialog: Goto({
            pane,
            directory,
            input: directory.to_string(),
            pending: false,
          }),
          dialog_error: "",
        },
        @rabbita.none,
      )
    Loaded(revision, path, include_markers, result) => {
      guard model.dialog_revision == revision &&
        model.dialog is Goto(context) &&
        context.pending else {
        return (model, @rabbita.none)
      }
      match result {
        Err(error) =>
          (
            {
              ..model,
              dialog: Goto({ ..context, pending: false, }),
              dialog_error: error.message(),
            },
            @rabbita.none,
          )
        Ok(entries) => {
          let (model, command) = model.navigate_to_directory(context.pane, path)
          let pane = model.pane_at(context.pane)
          let pane = {
            ..pane.with_entries(
              entries,
              model.sort_order(context.pane),
              filter?=model.entry_filter(context.pane),
            ),
            request_id: pane.request_id + 1,
            loading: Ready,
            refresh_pending: include_markers !=
            (model.entry_appearance != Plain),
          }
          (
            { ..model, panes: set_pane(model.panes, context.pane, pane), },
            @rabbita.batch([command, @dialog.close(DialogId)]),
          )
        }
      }
    }
  }
}

///|
fn Model::submit_goto(
  model : Model,
  context : GotoContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard !context.pending else { return (model, @rabbita.none) }
  guard !context.input.is_empty() else {
    return (
      { ..model, dialog_error: "Directory path is required", },
      @rabbita.none,
    )
  }
  let path = context.directory.resolve(Path(context.input)) catch {
    error =>
      return ({ ..model, dialog_error: error.to_string(), }, @rabbita.none)
  }
  let revision = model.dialog_revision + 1
  let include_markers = model.entry_appearance != Plain
  (
    { ..model, dialog: Goto({ ..context, pending: true, }), dialog_error: "", },
    request_api(
      "/api/list",
      body=ToJson::to_json(@tuzi.ListingRequest::{ path, include_markers, }),
      result => emit(GotoEvent(Loaded(revision, path, include_markers, result))),
    ),
  )
}

///|
fn goto_dialog(context : GotoContext, error : String, emit : Emit[Msg]) -> Html {
  modal("Go to directory", emit, [
    dialog_input(
      "Directory path:",
      context.input,
      error,
      emit,
      description="Enter an absolute path or a path relative to \{context.directory}. Use / as the path separator.",
    ),
    dialog_confirm_footer_view(
      label=if context.pending { "Opening…" } else { "Go" },
      on_confirm=emit(DialogSubmit),
      disabled=context.pending,
    ),
  ])
}
