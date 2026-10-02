///|
priv struct InfoContext {
  id : Int
  entry : Entry
  path : Path
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
  }
  let model = {
    ..model,
    next_info_id: model.next_info_id + 1,
    dialog_error: "",
  }
  if entry.name == ".git" {
    let git : GitContext = { entry: context, panel: GitPanel::initialize(), }
    ({ ..model, dialog: GitInfo(git), }, request_git_info(git, emit))
  } else {
    ({ ..model, dialog: Info(context), }, @rabbita.none)
  }
}
