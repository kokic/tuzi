///|
priv struct InfoContext {
  id : Int32
  entry : Entry
  path : Path
  link : LinkFields?
  font_preview : FontPreview?
} derive(Eq)

///|
fn Model::open_info_dialog(
  model : Model,
  target : OpenTarget,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let { path, entry, .. } = target
  let context : InfoContext = {
    id: model.next_info_id,
    entry,
    path,
    font_preview: if entry.kind is Ok(kind) &&
      !kind.is_dir() &&
      @tuzi.font_content_type(entry.name) is Some(_) {
      Some(FontPreview::initialize())
    } else {
      None
    },
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
