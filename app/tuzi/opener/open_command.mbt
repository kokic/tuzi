///|
priv enum OpenArgument {
  Literal(String)
  Target
}

///|
priv struct OpenCommand {
  program : String
  arguments : Array[OpenArgument]
}

///|
/// The caller supplies a URL or an already-resolved native path. Launched
/// applications intentionally outlive both the request and the Tuzi process.
async fn OpenCommand::launch(
  self : OpenCommand,
  target : String,
  write_launch_log? : (async (String) -> Unit)? = None,
  no_console_window? : Bool = false,
) -> Unit {
  let arguments = self.arguments.map(argument => {
    match argument {
      Literal(value) => value
      Target => target
    }
  })
  if write_launch_log is Some(write_launch_log) {
    write_launch_log("open: \{self.program} \{arguments.to_json().stringify()}")
  }
  ignore(@process.spawn_orphan(self.program, arguments, no_console_window~))
}
