///|
priv enum GitMsg {
  GitRefresh(Int)
  GitLoaded(Int, Int, Result[@tuzi.GitInfo, RequestFailure])
  GitSelectBranch(Int, String)
  GitRun(Int, GitOperation)
  GitRenameOpen(Int)
}

///|
priv struct GitContext {
  entry : InfoContext
  panel : GitPanel
} derive(Eq)

///|
priv struct GitPanel {
  info : @tuzi.GitInfo?
  loading : Bool
  request_id : Int
  selected : String
  error : String
} derive(Eq)

///|
fn GitPanel::initialize() -> GitPanel {
  { info: None, loading: true, request_id: 0, selected: "", error: "", }
}

///|
fn GitPanel::receive(
  self : GitPanel,
  result : Result[@tuzi.GitInfo, RequestFailure],
) -> GitPanel {
  match result {
    Ok(info) =>
      {
        ..self,
        info: Some(info),
        loading: false,
        error: "",
        selected: if info.branches.any(branch => {
            branch.reference == self.selected
          }) {
          self.selected
        } else {
          ""
        },
      }
    Err(error) => { ..self, loading: false, error: error.message(), }
  }
}

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
fn git_branch_is_current(
  branch : @tuzi.GitBranch,
  info : @tuzi.GitInfo,
) -> Bool {
  branch.reference == "refs/heads/" + info.current
}

///|
fn git_branch_can_delete(
  branch : @tuzi.GitBranch,
  info : @tuzi.GitInfo,
) -> Bool {
  branch.local_name() is Some(_) && !git_branch_is_current(branch, info)
}

///|
/// Only local branches can be renamed; `git branch -m` works on the current
/// branch too.
fn git_branch_can_rename(branch : @tuzi.GitBranch) -> Bool {
  branch.local_name() is Some(_)
}

///|
fn Model::open_git_rename(model : Model, id : Int) -> Model {
  guard model.dialog is GitInfo(context) &&
    context.entry.id == id &&
    !context.panel.loading &&
    !model.git_busy(context.entry.path) &&
    context.panel.info is Some(info) else {
    return model
  }
  guard info.branches
    .iter()
    .find_first(branch => {
      branch.reference == context.panel.selected &&
      git_branch_can_rename(branch)
    })
    is Some(branch) else {
    return model
  }
  {
    ..model,
    dialog: GitRenameInput(
      context~,
      reference=branch.reference,
      input=branch.name,
    ),
    dialog_error: "",
  }
}

///|
fn Model::submit_git_rename(
  model : Model,
  context : GitContext,
  reference : String,
  input : String,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  let name = input
  guard !name.is_empty() else {
    return ({ ..model, dialog_error: "Name is required", }, @rabbita.none)
  }
  guard !context.panel.loading &&
    !model.git_busy(context.entry.path) &&
    context.panel.info is Some(info) &&
    info.available else {
    return (model, @rabbita.none)
  }
  let updated = { ..model, dialog: GitInfo(context), dialog_error: "", }
  updated
  .submit_tasks(
    [
      Git({
        path: context.entry.path,
        operation: RenameBranch(reference, name),
      }),
    ],
    emit,
    context=GitRename(
      dialog_revision=model.dialog_revision + 1,
      context~,
      input_dialog=model.dialog,
    ),
  )
  .unwrap_or((model, @rabbita.none))
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
