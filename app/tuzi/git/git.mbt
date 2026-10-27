///|
using @uniform_path {type Path}

///|
pub suberror GitError {
  GitMissing
  InvalidGitPath(Path)
  InvalidLocalReference(String)
  InvalidSwitchReference(String)
  WorktreeNotFound(Path)
  WorktreeInUse(Path)
  CommandFailed(code~ : Int32, stdout~ : String, stderr~ : String)
}

///|
pub extend GitError with Show::{to_string, output}

///|
pub impl Show for GitError with fn to_string(self) {
  match self {
    GitMissing => "Install Git to enable this operation"
    InvalidGitPath(_) => "Expected a .git file or directory"
    InvalidLocalReference(_) => "Expected a local branch reference"
    InvalidSwitchReference(_) => "Expected a local or remote branch reference"
    WorktreeNotFound(path) => "No Git worktree is registered at \{path}"
    WorktreeInUse(path) =>
      "Cannot remove the worktree at \{path}: it is the main worktree, the current worktree, or locked"
    CommandFailed(code~, stdout~, stderr~) => {
      let output = (stdout + stderr).trim().to_owned()
      guard !output.is_empty() else { "Git exited with status \{code}" }
      output
    }
  }
}

///|
async fn git_command(arguments : Array[String]) -> (Int32, String, String) {
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
    ["-C", directory.to_native(), "-c", "color.ui=false", ..arguments],
  )
  guard code == 0 else { raise CommandFailed(code~, stdout~, stderr~) }
  (stdout, stderr)
}

///|
pub async fn read_git_info(path : Path) -> @shared.GitInfo {
  guard path.basename() == ".git" else { raise InvalidGitPath(path) }
  let directory = path.dirname()
  let (output, _) = checked_git(directory, [
    "for-each-ref", "--format=%(refname)%09%(refname:short)%09%(symref)", "refs/heads/",
    "refs/remotes/",
  ]) catch {
    GitMissing =>
      return { available: false, current: "", branches: [], worktrees: [], }
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
    directory.to_native(),
    "symbolic-ref",
    "--quiet",
    "--short",
    "HEAD",
  ])
  guard code == 0 || code == 1 else {
    raise CommandFailed(code~, stdout=current, stderr~)
  }
  {
    available: true,
    current: current.trim().to_owned(),
    branches,
    worktrees: read_worktrees(directory),
  }
}

///|
/// Reads the worktrees registered for the repository checked out at `directory`.
async fn read_worktrees(directory : Path) -> Array[@shared.GitWorktree] {
  let (output, _) = checked_git(directory, ["worktree", "list", "--porcelain"])
  parse_worktree_list(output, current_worktree_path(directory))
}

///|
/// Path of the worktree `directory` itself, as Git reports it.
async fn current_worktree_path(directory : Path) -> String {
  let (code, stdout, _) = git_command([
    "-C",
    directory.to_native(),
    "rev-parse",
    "--path-format=absolute",
    "--show-toplevel",
  ]) catch {
    _ => return ""
  }
  guard code == 0 else { return "" }
  stdout.trim().to_owned()
}

///|
fn parse_worktree_list(
  output : String,
  current : String,
) -> Array[@shared.GitWorktree] {
  let blocks : Array[String] = []
  let lines : Array[String] = []
  for line in output.split("\n") {
    let line = line.trim()
    if line.is_empty() {
      if !lines.is_empty() {
        blocks.push(lines.join("\n"))
        lines.clear()
      }
    } else {
      lines.push(line.to_owned())
    }
  }
  if !lines.is_empty() {
    blocks.push(lines.join("\n"))
  }
  let worktrees : Array[@shared.GitWorktree] = []
  for index, block in blocks {
    if parse_worktree_block(block, index, current) is Some(worktree) {
      worktrees.push(worktree)
    }
  }
  worktrees
}

///|
fn parse_worktree_block(
  block : String,
  index : Int32,
  current : String,
) -> @shared.GitWorktree? {
  let lines = block.split("\n").filter(line => !line.is_empty()).to_array()
  let field = prefix => {
    lines
    .iter()
    .find_first(line => line.has_prefix(prefix))
    .map(line => line[prefix.length():].trim().to_owned())
  }
  guard field("worktree ") is Some(path) else { return None }
  Some({
    path: Path(path),
    head: field("HEAD ").unwrap_or(""),
    branch: field("branch "),
    main: index == 0,
    current: path == current,
    bare: lines.contains("bare"),
    detached: lines.contains("detached"),
    locked: lines.any(line => line == "locked" || line.has_prefix("locked ")),
    prunable: lines.any(line => {
      line == "prunable" || line.has_prefix("prunable ")
    }),
  })
}
