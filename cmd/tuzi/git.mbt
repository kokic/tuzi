///|
priv suberror GitError {
  GitMissing
  CommandFailed(String)
}

///|
/// Argument arrays keep paths and branch names out of shell syntax.
async fn git_command(arguments : Array[String]) -> (Int, String, String) {
  let (stdin, writer) = @process.write_to_process()
  writer.close()
  let (code, stdout, stderr) = @process.collect_output(
    "git",
    arguments,
    stdin~,
    extra_env={ "GIT_TERMINAL_PROMPT": "0", "GCM_INTERACTIVE": "Never" },
    no_console_window=true,
  ) catch {
    @os_error.OSError(_, ..) as error if error.is_ENOENT() => raise GitMissing
    error => raise error
  }
  (code, stdout.text(), stderr.text())
}

///|
async fn checked_git(
  directory : Path,
  arguments : Array[String],
) -> (String, String) {
  let (code, stdout, stderr) = git_command(
    ["-C", directory.to_string(), "-c", "color.ui=false", ..arguments],
  )
  guard code == 0 else {
    let output = "\{stdout}\{stderr}".trim().to_owned()
    raise CommandFailed(
      if output.is_empty() {
        "Git exited with status \{code}"
      } else {
        output
      },
    )
  }
  (stdout, stderr)
}

///|
async fn read_git_info(path : Path) -> @shared.GitInfo {
  guard path.basename() == ".git" else {
    raise CommandFailed("Expected a .git file or directory")
  }
  let directory = path.dirname()
  let (output, _) = checked_git(directory, [
    "for-each-ref", "--format=%(refname)%09%(refname:short)%09%(symref)", "refs/heads/",
    "refs/remotes/",
  ]) catch {
    GitMissing => return { available: false, current: "", branches: [], }
    error => raise error
  }
  let branches : Array[@shared.GitBranch] = []
  for line in output.split("\n") {
    guard line.split("\t").to_array() is [reference, name, symbolic] &&
      symbolic.trim().is_empty() else {
      continue
    }
    branches.push({ reference: reference.to_owned(), name: name.to_owned(), })
  }
  let (code, current, stderr) = git_command([
    "-C",
    directory.to_string(),
    "symbolic-ref",
    "--quiet",
    "--short",
    "HEAD",
  ])
  guard code == 0 || code == 1 else { raise CommandFailed(stderr) }
  { available: true, current: current.trim().to_owned(), branches, }
}

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
