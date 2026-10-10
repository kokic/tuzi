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
pub struct OpenService {
  registry : @shared.OpenRegistry
  priv commands : Map[String, OpenCommand]
}

///|
pub suberror OpenError {
  UnknownOpener(String)
  DefaultNotListed(String)
  NotApplicable(String)
  UnsupportedTarget(String)
  ProgramMissing(String)
}

///|
pub extend OpenError with Show::{to_string, output}

///|
pub impl Show for OpenError with fn to_string(self) {
  match self {
    UnknownOpener(id) => "Unknown opener: \{id}"
    DefaultNotListed(id) =>
      "Default opener must be listed in its association: \{id}"
    NotApplicable(id) => "Opener is not available for this target: \{id}"
    UnsupportedTarget(path) => "Not a regular file or directory: \{path}"
    ProgramMissing(program) =>
      "Program not found: \{program}. Install it or update the opener configuration."
  }
}

///|
pub fn OpenService::new() -> OpenService raise OpenError {
  let definitions = configured_openers()
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
pub async fn OpenService::open(
  self : OpenService,
  request : @shared.OpenRequest,
) -> Unit {
  // Resolve on the host and inspect the current target instead of trusting UI metadata.
  let native = request.path.to_native()
  let native = {
    guard !@path.Path(native).is_absolute() else { native }
    @path.Path(native).resolve().to_string()
  }
  let path = @fsops.path_from_native(native)
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
  command.launch(native, no_console_window=true) catch {
    @os_error.OSError(_, ..) as error if error.is_ENOENT() =>
      raise ProgramMissing(command.program)
    error => raise error
  }
}
