///|
/// URL opening and directory browsing have different Windows commands.
priv enum SystemOpenKind {
  Url
  Directory
}

///|
/// Select the implementation for the native compilation target.
#cfg(platform="windows")
fn system_open_command(kind : SystemOpenKind) -> OpenCommand {
  match kind {
    Url =>
      {
        program: "cmd",
        // The empty argument is start's window title, before the URL.
        arguments: [Literal("/c"), Literal("start"), Literal(""), Target],
      }
    Directory => { program: "explorer.exe", arguments: [Target], }
  }
}

///|
#cfg(platform="macos")
fn system_open_command(kind : SystemOpenKind) -> OpenCommand {
  {
    // Preserve URL opening through PATH and the directory opener's full path.
    program: match kind {
      Url => "open"
      Directory => "/usr/bin/open"
    },
    arguments: [Target],
  }
}

///|
#cfg(platform="linux")
fn system_open_command(_kind : SystemOpenKind) -> OpenCommand {
  { program: "xdg-open", arguments: [Target], }
}
