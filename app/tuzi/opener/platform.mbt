///|
pub async fn open_url(url : String) -> Unit {
  system_open_command(Url).launch(url)
}

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
#cfg(not(platform="windows"))
fn system_open_command(kind : SystemOpenKind) -> OpenCommand {
  match @async.platform {
    MacOS =>
      {
        // Preserve URL opening through PATH and the directory opener's full path.
        program: match kind {
          Url => "open"
          Directory => "/usr/bin/open"
        },
        arguments: [Target],
      }
    Linux => { program: "xdg-open", arguments: [Target], }
    Windows => panic()
  }
}
