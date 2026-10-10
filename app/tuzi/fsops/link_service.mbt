///|
pub suberror LinkError {
  AbsolutePathRequired(Path)
  LinkCommandFailed(String, Int, String)
  RecoveryFailed(Path, Error)
}

///|
pub extend LinkError with Show::{to_string, output}

///|
pub impl Show for LinkError with fn to_string(self) {
  match self {
    AbsolutePathRequired(path) => "An absolute path is required: \{path}"
    LinkCommandFailed(program, code, output) =>
      "\{program} exited with status \{code}: \{output}"
    RecoveryFailed(path, error) =>
      "Link recovery failed; preserved link at \{path}: \{error}"
  }
}

///|
pub fn validate_link_target(path : Path) -> Unit raise {
  guard @path.Path(path.to_native()).is_absolute() &&
    !path.to_string().contains("\u0000") else {
    raise LinkError::AbsolutePathRequired(path)
  }
}

///|
pub fn validate_link_path(path : Path) -> Unit raise {
  validate_link_target(path)
  validate_entry_name(path.basename())
}

///|
/// Paths travel as process arguments or environment values, never shell code.
async fn link_command(
  program : String,
  arguments : Array[String],
  extra_env? : Map[String, String] = {},
) -> String {
  let (stdin, writer) = @process.write_to_process()
  writer.close()
  let (code, stdout, stderr) = @process.collect_output(
    program,
    arguments,
    stdin~,
    extra_env~,
    no_console_window=true,
  )
  guard code == 0 else {
    raise LinkError::LinkCommandFailed(
      program,
      code,
      stdout.text() + stderr.text(),
    )
  }
  stdout.text()
}

///|
pub async fn read_link_target(path : Path) -> Path {
  validate_link_path(path)
  guard @async_fs.kind(path.to_native(), follow_symlink=false) is SymLink else {
    raise FileError::UnsupportedEntry(path.to_string())
  }
  let target = path_from_native(read_link_text(path))
  // Resolve relative targets against the link's parent, preserving link chains.
  path_from_native(@async_fs.realpath(path.dirname().to_native())).resolve(
    target,
  )
}

///|
async fn canonical_link_path(path : Path) -> Path {
  path_from_native(@async_fs.realpath(path.dirname().to_native())).join(
    Path("./\{path.basename()}"),
  )
}

///|
/// Stage the replacement before touching the old link. The transaction is not
/// cancelled between replacement and cleanup; failures restore the old entry.
pub async fn edit_link(
  source : Path,
  destination : Path,
  target : Path,
) -> Unit {
  let source = canonical_link_path(source)
  let destination = canonical_link_path(destination)
  guard @async_fs.kind(source.to_native(), follow_symlink=false) is SymLink else {
    raise FileError::UnsupportedEntry(source.to_string())
  }
  @async.protect_from_cancel(() => {
    let token = path_from_native(@async_fs.tmpdir(prefix="tuzi-link"))
    defer @async_fs.rmdir(token.to_native())
    let staging = destination.dirname().join(Path("./.\{token.basename()}"))
    @async_fs.mkdir(staging.to_native())
    let replacement = staging.join(Path("new"))
    let backup = staging.join(Path("previous"))
    {
      errdefer @async_fs.rmdir(staging.to_native())
      create_link_like(source, replacement, target)
    }
    let same_path = filesystem_path_key(source) ==
      filesystem_path_key(destination)
    if same_path {
      errdefer {
        @async_fs.remove(replacement.to_native())
        @async_fs.rmdir(staging.to_native())
      }
      relocate_link(source, backup)
    }
    {
      errdefer {
        if same_path {
          relocate_link(backup, source) catch {
            recovery => raise LinkError::RecoveryFailed(backup, recovery)
          }
        }
        @async_fs.remove(replacement.to_native())
        @async_fs.rmdir(staging.to_native())
      }
      relocate_link(replacement, destination)
    }
    let previous = if same_path { backup } else { source }
    {
      errdefer {
        @async_fs.remove(destination.to_native()) catch {
          recovery => raise LinkError::RecoveryFailed(previous, recovery)
        }
        if same_path {
          relocate_link(backup, source) catch {
            recovery => raise LinkError::RecoveryFailed(backup, recovery)
          }
        }
        @async_fs.rmdir(staging.to_native())
      }
      @async_fs.remove(previous.to_native())
    }
    @async_fs.rmdir(staging.to_native())
  })
}
