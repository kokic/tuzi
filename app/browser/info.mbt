///|
priv struct InfoContext {
  id : Int
  entry : Entry
  path : Path
  link : LinkFields?
} derive(Eq)

///|
fn Model::open_info_dialog(model : Model, emit : Emit[Msg]) -> (Model, Cmd) {
  let pane = model.pane_at(model.active)
  guard pane.cursor_entry(filter?=model.entry_filter(model.active))
    is Some(entry) else {
    return (model, @rabbita.none)
  }
  let path = pane.path.join(Path("./\{entry.name}"))
  let context : InfoContext = {
    id: model.next_info_id,
    entry,
    path,
    link: if entry.kind.is_link() {
      Some({ path: path.to_string(), target: None, })
    } else {
      None
    },
  }
  let model = {
    ..model,
    next_info_id: model.next_info_id + 1,
    dialog_error: "",
  }
  let link_request = if entry.kind.is_link() {
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
