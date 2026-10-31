///|
pub suberror GitBusy {
  GitBusy
}

///|
let git_locks : Map[String, @async.Mutex] = Map([])

///|
pub fn git_arguments(
  operation : @shared.GitOperation,
) -> Array[String] raise GitError {
  match operation {
    Pull => ["pull", "--ff-only"]
    Push => ["push"]
    Prune => ["remote", "prune", "origin"]
    PruneWorktrees => ["worktree", "prune"]
    RemoveWorktree(target) =>
      ["worktree", "remove", "--force", "--", target.to_native()]
    DeleteBranch(target) => {
      guard target.strip_prefix("refs/heads/") is Some(name) else {
        raise InvalidLocalReference(target)
      }
      ["branch", "-D", "--", name.to_owned()]
    }
    RenameBranch(target, new_name) => {
      guard target.strip_prefix("refs/heads/") is Some(name) else {
        raise InvalidLocalReference(target)
      }
      ["branch", "-m", "--", name.to_owned(), new_name]
    }
    Switch(target) =>
      match () {
        _ if target.has_prefix("refs/remotes/") =>
          ["switch", "--track", "--", target]
        _ if target.strip_prefix("refs/heads/") is Some(name) =>
          ["switch", "--no-guess", "--", name.to_owned()]
        _ => raise InvalidSwitchReference(target)
      }
  }
}

///|
pub async fn run_git(path : Path, operation : @shared.GitOperation) -> String {
  let (common, _) = checked_git(path.dirname(), [
    "rev-parse", "--path-format=absolute", "--git-common-dir",
  ])
  let key = @fsops.filesystem_path_key(
    @fsops.path_from_native(@async_fs.realpath(common.trim().to_owned())),
  )
  let lock = git_locks.get_or_init(key, () => @async.Mutex())
  guard lock.try_acquire() else { raise GitBusy }
  defer {
    lock.release()
    git_locks.remove(key)
  }
  let arguments = git_arguments(operation)
  if operation is RemoveWorktree(target) {
    validate_worktree_removal(path.dirname(), target)
  }
  let (stdout, stderr) = checked_git(path.dirname(), arguments)
  stdout + stderr
}

///|
/// Checks the removal target against the worktrees Git reports, so a
/// client-supplied path can never remove anything else.
async fn validate_worktree_removal(directory : Path, target : Path) -> Unit {
  let worktrees = read_worktrees(directory)
  guard worktrees.iter().find_first(worktree => worktree.path == target)
    is Some(worktree) else {
    raise WorktreeNotFound(target)
  }
  guard worktree.can_remove() else { raise WorktreeInUse(target) }
}
