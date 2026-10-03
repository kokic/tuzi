///|
priv struct InfoContext {
  id : Int
  entry : Entry
  path : Path
  link : LinkFields?
} derive(Eq)

///|
priv struct InfoField {
  label : String
  value : String
}

///|
fn Model::open_info_dialog(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  let pane = model.pane_at(model.active)
  guard pane.cursor_entry(filter?=model.entry_filter(model.active))
    is Some(entry) else {
    return (model, @rabbita.none)
  }
  let context : InfoContext = {
    id: model.next_info_id,
    entry,
    path: pane.path.join(Path("./\{entry.name}")),
    link: if entry.is_symlink {
      Some({
        path: pane.path.join(Path("./\{entry.name}")).to_string(),
        target: None,
      })
    } else {
      None
    },
  }
  let model = {
    ..model,
    next_info_id: model.next_info_id + 1,
    dialog_error: "",
  }
  let link_request = if entry.is_symlink {
    request_link_target(context, emit)
  } else {
    @rabbita.none
  }
  if entry.name == ".git" {
    let git : GitContext = { entry: context, panel: GitPanel::initialize(), }
    (
      { ..model, dialog: GitInfo(git), },
      @rabbita.batch([request_git_info(git, emit), link_request]),
    )
  } else {
    ({ ..model, dialog: Info(context), }, link_request)
  }
}
