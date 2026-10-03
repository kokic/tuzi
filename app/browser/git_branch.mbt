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
