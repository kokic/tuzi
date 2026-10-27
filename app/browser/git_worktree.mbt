///|
fn Model::open_worktree_removal(
  model : Model,
  id : Int32,
  path : Path,
) -> Model {
  guard model.dialog is GitInfo(context) &&
    context.entry.id == id &&
    !context.panel.loading &&
    !model.git_busy(context.entry.path) &&
    context.panel.info is Some(info) else {
    return model
  }
  guard info.worktrees
    .iter()
    .find_first(worktree => worktree.path == path && worktree.can_remove())
    is Some(worktree) else {
    return model
  }
  {
    ..model,
    dialog: RemoveWorktreeConfirm(context~, worktree~),
    dialog_error: "",
  }
}

///|
fn Model::submit_worktree_removal(
  model : Model,
  context : GitContext,
  worktree : @tuzi.GitWorktree,
  emit : Emit[Msg],
) -> (Model, Cmd) {
  guard !context.panel.loading &&
    !model.git_busy(context.entry.path) &&
    context.panel.info is Some(info) &&
    info.worktrees.any(registered => {
      registered.path == worktree.path && registered.can_remove()
    }) else {
    return (model, @rabbita.none)
  }
  let updated = { ..model, dialog: GitInfo(context), dialog_error: "", }
  updated
  .submit_tasks(
    [
      Git({
        path: context.entry.path,
        operation: RemoveWorktree(worktree.path),
      }),
    ],
    emit,
    context=GitDialog(
      dialog_revision=model.dialog_revision + 1,
      context~,
      restore=RemoveWorktreeConfirm(context~, worktree~),
    ),
  )
  .unwrap_or((model, @rabbita.none))
}
