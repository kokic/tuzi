///|
using @uniform_path {type Path}

///|
pub suberror GitError {
  GitMissing
  InvalidGitPath(Path)
  InvalidLocalReference(String)
  InvalidSwitchReference(String)
  CommandFailed(code~ : Int, stdout~ : String, stderr~ : String)
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
    CommandFailed(code~, stdout~, stderr~) => {
      let output = (stdout + stderr).trim().to_owned()
      guard !output.is_empty() else { "Git exited with status \{code}" }
      output
    }
  }
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
    directory.to_native(),
    "symbolic-ref",
    "--quiet",
    "--short",
    "HEAD",
  ])
  guard code == 0 || code == 1 else {
    raise CommandFailed(code~, stdout=current, stderr~)
  }
  { available: true, current: current.trim().to_owned(), branches, }
}
