///|
priv enum OpenPlatform {
  Windows
  MacOS
  Linux
} derive(Eq)

///|
priv enum OpenArgument {
  Literal(String)
  TargetPath
}

///|
priv struct OpenCommand {
  program : String
  arguments : Array[OpenArgument]
}

///|
priv enum OpenExecution {
  Browse
  Preview
  ExtractZip
  External(OpenCommand)
}

///|
priv struct OpenDefinition {
  label : String
  execution : OpenExecution
}

///|
priv struct OpenService {
  registry : @shared.OpenRegistry
  commands : Map[String, OpenCommand]
}

///|
priv suberror OpenError {
  UnknownOpener(String)
  DefaultNotListed(String)
  NotApplicable(String)
  UnsupportedTarget(String)
  ProgramMissing(String)
}

///|
impl Show for OpenError with to_string(self) {
  match self {
    UnknownOpener(id) => "Unknown opener: \{id}"
    DefaultNotListed(id) => "Default opener must be listed in its association: \{id}"
    NotApplicable(id) => "Opener is not available for this target: \{id}"
    UnsupportedTarget(path) => "Not a regular file or directory: \{path}"
    ProgramMissing(program) => "Program not found: \{program}. Install it or update the opener configuration."
  }
}

///|
async fn OpenService::new() -> OpenService {
  let platform : OpenPlatform = if @path.sep == '\\' {
    Windows
  } else {
    let (_, output) = @process.collect_stdout("uname", [])
    if output.text().trim() == "Darwin" { MacOS } else { Linux }
  }
  let definitions = configured_openers(platform)
  let openers : Map[String, @shared.Opener] = Map([])
  let commands : Map[String, OpenCommand] = Map([])
  for id, definition in definitions {
    let action : @shared.OpenAction = match definition.execution {
      Browse => Browse
      Preview => Preview
      ExtractZip => ExtractZip
      External(command) => {
        commands[id] = command
        External
      }
    }
    openers[id] = { label: definition.label, action, }
  }
  let registry = configured_open_registry(openers)
  validate_open_association(registry.folder, openers)
  validate_open_association(registry.other_file, openers)
  for _, association in registry.filenames {
    validate_open_association(association, openers)
  }
  for _, association in registry.extensions {
    validate_open_association(association, openers)
  }
  { registry, commands, }
}

///|
fn validate_open_association(
  association : @shared.OpenAssociation,
  openers : Map[String, @shared.Opener],
) -> Unit raise OpenError {
  guard association.openers.contains(association.default_opener) else {
    raise DefaultNotListed(association.default_opener)
  }
  for id in association.openers {
    guard openers.get(id) is Some(_) else { raise UnknownOpener(id) }
  }
}

///|
async fn OpenService::open(self : OpenService, request : @shared.OpenRequest) -> Unit {
  // Resolve on the host and inspect the current target instead of trusting UI metadata.
  let native = @path.Path(request.path.to_string()).resolve().to_string()
  let path = Path::from_native(native)
  let is_dir = match @async_fs.kind(native) {
    Directory => true
    Regular => false
    _ => raise UnsupportedTarget(native)
  }
  let association = self.registry.for_entry(path.basename(), is_dir~)
  guard association.openers.contains(request.opener) &&
    self.commands.get(request.opener) is Some(command) else {
    raise NotApplicable(request.opener)
  }
  let arguments = command.arguments.map(argument => {
    match argument {
      Literal(value) => value
      TargetPath => native
    }
  })
  // Editors intentionally outlive both this request and the Tuzi process.
  ignore(@process.spawn_orphan(command.program, arguments, no_console_window=true)) catch {
    @os_error.OSError(_, ..) as error if error.is_ENOENT() =>
      raise ProgramMissing(command.program)
    error => raise error
  }
}

///|
/// Windows' `code` entry point is a batch script. Locate Code.exe so file paths
/// never go through cmd.exe. PATH also covers portable/custom installations.
async fn windows_vscode_program() -> String {
  let candidates : Array[Path] = []
  for directory in @env.get_env_var("PATH").unwrap_or("").split(";") {
    let directory = directory.trim().to_owned()
    guard !directory.is_empty() else { continue }
    let base = Path::from_native(directory)
    candidates.push(base.join(Path("Code.exe")))
    if base.basename().to_lower() == "bin" {
      candidates.push(base.dirname().join(Path("Code.exe")))
    }
  }
  if @env.get_env_var("LOCALAPPDATA") is Some(directory) {
    candidates.push(Path::from_native(directory).join(Path("Programs/Microsoft VS Code/Code.exe")))
  }
  for variable in ["ProgramFiles", "ProgramFiles(x86)"] {
    if @env.get_env_var(variable) is Some(directory) {
      candidates.push(Path::from_native(directory).join(Path("Microsoft VS Code/Code.exe")))
    }
  }
  for candidate in candidates {
    if @async_fs.exists(candidate.to_string()) {
      return candidate.to_string()
    }
  }
  "Code.exe"
}
