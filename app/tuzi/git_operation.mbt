///|
priv suberror GitBusy {
  GitBusy
}

///|
let git_locks : Map[String, @async.Mutex] = Map([])

///|
/// Build arguments and check reference kinds without accessing a repository.
fn git_arguments(
  operation : @shared.GitOperation,
) -> Array[String] raise GitError {
  match operation {
    Pull => ["pull", "--ff-only"]
    Push => ["push"]
    Prune => ["remote", "prune", "origin"]
    DeleteBranch(target) => {
      guard target.strip_prefix("refs/heads/") is Some(name) else {
        raise CommandFailed("Expected a local branch reference")
      }
      ["branch", "-D", "--", name.to_owned()]
    }
    RenameBranch(target, new_name) => {
      guard target.strip_prefix("refs/heads/") is Some(name) else {
        raise CommandFailed("Expected a local branch reference")
      }
      ["branch", "-m", "--", name.to_owned(), new_name]
    }
    Switch(target) =>
      match () {
        _ if target.has_prefix("refs/remotes/") =>
          ["switch", "--track", "--", target]
        _ if target.strip_prefix("refs/heads/") is Some(name) =>
          ["switch", "--no-guess", "--", name.to_owned()]
        _ => raise CommandFailed("Expected a local or remote branch reference")
      }
  }
}

///|
async fn run_git(path : Path, arguments : Array[String]) -> String {
  // Linked worktrees share refs: lock their common Git directory, not the UI path.
  let (common, _) = checked_git(path.dirname(), [
    "rev-parse", "--path-format=absolute", "--git-common-dir",
  ])
  let key = filesystem_path_key(
    Path::from_native(@async_fs.realpath(common.trim().to_owned())),
  )
  let lock = git_locks.get_or_init(key, () => @async.Mutex())
  guard lock.try_acquire() else { raise GitBusy }
  defer {
    lock.release()
    git_locks.remove(key)
  }
  let (stdout, stderr) = checked_git(path.dirname(), arguments)
  stdout + stderr
}
