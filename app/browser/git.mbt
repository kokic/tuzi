///|
fn request_git_info(context : GitContext, emit : Emit[Msg]) -> Cmd {
  request_api(
    "/api/git/info",
    body=ToJson::to_json(@tuzi.DirectoryRequest::{ path: context.entry.path, }),
    result => {
      emit(
        GitEvent(GitLoaded(context.entry.id, context.panel.request_id, result)),
      )
    },
  )
}

///|
fn Model::update_git(
  model : Model,
  msg : GitMsg,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  match msg {
    GitRefresh(id) => model.refresh_git(id, emit)
    GitRun(id, operation) => model.run_git_operation(id, operation, emit)
    GitRenameOpen(id) => (model.open_git_rename(id), @rabbita.none)
    GitLoaded(id, request_id, result) => {
      let dialog = match model.dialog {
        GitInfo(context) if context.entry.id == id &&
          context.panel.request_id == request_id =>
          GitInfo({ ..context, panel: context.panel.receive(result), })
        GitRenameInput(context~, reference~, input~) if context.entry.id == id &&
          context.panel.request_id == request_id =>
          GitRenameInput(
            context={ ..context, panel: context.panel.receive(result), },
            reference~,
            input~,
          )
        other => other
      }
      ({ ..model, dialog, }, @rabbita.none)
    }
    GitSelectBranch(id, selected) => {
      guard model.dialog is GitInfo(context) &&
        context.entry.id == id &&
        context.panel.info is Some(info) &&
        !context.panel.loading &&
        !model.git_busy(context.entry.path) &&
        info.branches.any(branch => branch.reference == selected) else {
        return (model, @rabbita.none)
      }
      (
        {
          ..model,
          dialog: GitInfo({ ..context, panel: { ..context.panel, selected, }, }),
        },
        @rabbita.none,
      )
    }
  }
}

///|
fn Model::git_busy(model : Model, path : Path) -> Bool {
  model.jobs.submitting ||
  model.jobs.items.any(task => {
    task.kind is Git(request) && request.path == path && task.status.is_active()
  })
}

///|
fn Model::run_git_operation(
  model : Model,
  id : Int,
  operation : GitOperation,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.dialog is GitInfo(context) &&
    context.entry.id == id &&
    !context.panel.loading &&
    !model.git_busy(context.entry.path) &&
    context.panel.info is Some(info) &&
    info.available else {
    return (model, @rabbita.none)
  }
  model
  .submit_tasks([Git({ path: context.entry.path, operation, })], emit)
  .unwrap_or((model, @rabbita.none))
}

///|
fn Model::refresh_git(
  model : Model,
  id : Int,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard model.dialog is GitInfo(context) &&
    context.entry.id == id &&
    !model.git_busy(context.entry.path) else {
    return (model, @rabbita.none)
  }
  let context = {
    ..context,
    panel: {
      ..context.panel,
      loading: true,
      request_id: context.panel.request_id + 1,
      error: "",
    },
  }
  ({ ..model, dialog: GitInfo(context), }, request_git_info(context, emit))
}
