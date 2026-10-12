///|
priv struct InfoContext {
  id : Int
  entry : Entry
  path : Path
  link : LinkFields?
} derive(Eq)

///|
fn Model::open_info_dialog(
  model : Model,
  context : FileActionContext,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard context.cursor is Some(target) else { return (model, @rabbita.none) }
  let { path, entry, .. } = target
  let context : InfoContext = {
    id: model.next_info_id,
    entry,
    path,
    link: if entry.is_link() {
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
  let link_request = if entry.is_link() {
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
